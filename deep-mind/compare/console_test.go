package consolelog

import (
	"bytes"
	"encoding/json"
	"io"
	"io/ioutil"
	"os"
	"strings"
	"testing"

	"github.com/eoscanada/capture/hlog"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestReferenceAnalysis_AcceptedBlocks(t *testing.T) {
	f, err := os.Create("output.jsonl")
	require.NoError(t, err)
	defer f.Close()

	enc := json.NewEncoder(f)
	enc.SetIndent("", " ")

	for _, block := range readAllBlocks(t, "output.log") {
		require.NoError(t, err)
		enc.Encode(block)
	}
	f.Close()

	assertFileContentEqual(t, "reference.jsonl", "output.jsonl")
}

func TestReferenceAnalysis(t *testing.T) {
	stats := computeDeepMindStats(readAllBlocks(t, "output.log"))
	content, _ := json.Marshal(stats)
	err := ioutil.WriteFile("output.stats.json", content, 0644)
	require.NoError(t, err)

	assertFileContentEqual(t, "reference.stats.json", "output.stats.json")
}

func TestRamTraces_RunningUpBalanceChecks(t *testing.T) {
	payerToBalanceMap := map[string]int64{}
	for _, block := range readAllBlocks(t, "output.log") {
		for _, ramOp := range getOrderedRAMOps(block) {
			payer, delta, usage := ramOp.Payer, ramOp.Delta, int64(ramOp.Usage)
			previousBalance, present := payerToBalanceMap[payer]

			if !present {
				assert.Equal(t, delta, usage, "For new account, usage & delta should the same since just created")
			} else {
				assert.Equal(t, previousBalance+delta, usage, "Previous balance + delta should equal new usage")
			}

			payerToBalanceMap[payer] = usage
		}
	}
}

func assertFileContentEqual(t *testing.T, expectedFile string, actualFile string) {
	expected, err := ioutil.ReadFile(expectedFile)
	require.NoError(t, err)
	actual, err := ioutil.ReadFile(actualFile)
	require.NoError(t, err)

	assert.Truef(t, bytes.Compare(expected, actual) == 0, "%s and %s differ, run 'diff -u %s %s'", expectedFile, actualFile, expectedFile, actualFile)
}

func readAllBlocks(t *testing.T, nodeosLogFile string) []*hlog.AcceptedBlock {
	blocks := []*hlog.AcceptedBlock{}

	reader, err := hlog.NewFileConsoleReader(nodeosLogFile)
	require.NoError(t, err)
	defer reader.Close()

	for {
		el, err := reader.Read()
		if err == io.EOF {
			break
		}

		require.NoError(t, err)

		block, ok := el.(*hlog.AcceptedBlock)
		require.True(t, ok, "Type conversion should have been correct")

		blocks = append(blocks, block)
	}

	return blocks
}

func computeDeepMindStats(blocks []*hlog.AcceptedBlock) *ReferenceStats {
	stats := &ReferenceStats{}
	for _, block := range blocks {
		stats.TransactionCount += int64(len(block.AllTransactionTraces()))

		adjustDeepMindDBOpsStats(block, stats)
		adjustDeepMindRAMOpsStats(block, stats)
		adjustDeepMindDTrxOpsStats(block, stats)
	}

	return stats
}

func adjustDeepMindDBOpsStats(block *hlog.AcceptedBlock, stats *ReferenceStats) {
	for _, ops := range block.DBOps {
		for _, op := range ops {
			if strings.Contains(op.NewPayer, "battlefield") || strings.Contains(op.OldPayer, "battlefield") {
				stats.DBOpCount++
			}
		}
	}
}

func adjustDeepMindRAMOpsStats(block *hlog.AcceptedBlock, stats *ReferenceStats) {
	for _, ops := range block.RAMOps {
		for _, op := range ops {
			if strings.Contains(op.Payer, "battlefield") {
				stats.RAMOpCount++
			}
		}
	}
}

func adjustDeepMindDTrxOpsStats(block *hlog.AcceptedBlock, stats *ReferenceStats) {
	for _, ops := range block.DTrxOps {
		for _, op := range ops {
			if strings.Contains(op.Payer, "battlefield") {
				stats.RAMOpCount++
			}
		}
	}
}

func getOrderedRAMOps(block *hlog.AcceptedBlock) []*hlog.RAMOp {
	ramOps := []*hlog.RAMOp{}
	for _, transactionID := range getOrderedTransactionIDs(block) {
		ramOps = append(ramOps, block.RAMOps[hlog.TransactionID(transactionID)]...)
	}

	return ramOps
}

func getOrderedTransactionIDs(block *hlog.AcceptedBlock) []string {
	return block.TransactionIDs()
}

type ReferenceStats = struct {
	TransactionCount int64
	DBOpCount        int64
	RAMOpCount       int64
	DTrxOpCount      int64
}
