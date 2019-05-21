package compare

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"os"
	"strings"
	"testing"

	"github.com/eoscanada/bstream/hlog"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestReferenceAnalysis_AcceptedBlocks(t *testing.T) {
	f, err := os.Create("output.jsonl")
	require.NoError(t, err)
	defer f.Close()

	enc := json.NewEncoder(f)

	for _, block := range readAllBlocks(t, "output.log") {
		require.NoError(t, err)
		enc.Encode(block)
	}
	f.Close()

	assertJsonlContentEqual(t, "reference.jsonl", "output.jsonl")
}

func TestReferenceAnalysis(t *testing.T) {
	stats := computeDeepMindStats(readAllBlocks(t, "output.log"))
	actual, _ := json.MarshalIndent(stats, "", "  ")
	err := ioutil.WriteFile("output.stats.json", actual, 0644)
	require.NoError(t, err)

	expected, err := ioutil.ReadFile("reference.stats.json")
	require.NoError(t, err)

	assert.JSONEq(t, string(expected), string(actual), "Reference stats and actual stats differs, run `diff -u output.stats.json reference.stats.json` for details")
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

func assertJsonlContentEqual(t *testing.T, expectedFile string, actualFile string) {
	expected, err := ioutil.ReadFile(expectedFile)
	require.NoError(t, err)
	actual, err := ioutil.ReadFile(actualFile)
	require.NoError(t, err)

	actualString := strings.TrimSpace(string(actual))
	expectedString := strings.TrimSpace(string(expected))

	actualLines := strings.Split(actualString, "\n")
	expectedLines := strings.Split(expectedString, "\n")

	for i, expectedLine := range expectedLines {
		assert.JSONEq(t, expectedLine, actualLines[i], "line #%d differs", i)
	}

	// We have it at the end to make it more discoverable by being the last failure emitted after (possibily) a long blob of text
	assert.Equal(t, len(expectedLines), len(actualLines), "lines length differs")
}

func readAllBlocks(t *testing.T, nodeosLogFile string) []*hlog.Block {
	blocks := []*hlog.Block{}

	reader, err := hlog.NewFileConsoleReader(nodeosLogFile)
	require.NoError(t, err)
	defer reader.Close()

	for {
		el, err := reader.Read()
		if err == io.EOF {
			break
		}

		require.NoError(t, err)

		block, ok := el.(*hlog.Block)
		require.True(t, ok, "Type conversion should have been correct")

		blocks = append(blocks, block)
	}

	return blocks
}

func computeDeepMindStats(blocks []*hlog.Block) *ReferenceStats {
	stats := &ReferenceStats{}
	for _, block := range blocks {
		stats.TransactionCount += int64(len(block.AllTransactionTraces()))

		adjustDeepMindCreationTreeStats(block, stats)
		adjustDeepMindDBOpsStats(block, stats)
		adjustDeepMindDTrxOpsStats(block, stats)
		adjustDeepMindFeatureOpsStats(block, stats)
		adjustDeepMindPermOpsStats(block, stats)
		adjustDeepMindRAMOpsStats(block, stats)
		adjustDeepMindRAMCorrectionOpsStats(block, stats)
		adjustDeepMindRLimitOpsStats(block, stats)
		adjustDeepMindTableOpsStats(block, stats)
	}

	return stats
}

func adjustDeepMindCreationTreeStats(block *hlog.Block, stats *ReferenceStats) {
	for _, creationTree := range block.CreationTree {
		for range creationTree {
			stats.CreationTreeNodeCount++
		}
	}
}

func adjustDeepMindDBOpsStats(block *hlog.Block, stats *ReferenceStats) {
	for _, ops := range block.DBOps {
		for _, op := range ops {
			if strings.Contains(op.NewPayer, "battlefield") || strings.Contains(op.OldPayer, "battlefield") {
				stats.DBOpCount++
			}
		}
	}
}

func adjustDeepMindDTrxOpsStats(block *hlog.Block, stats *ReferenceStats) {
	for _, ops := range block.DTrxOps {
		for _, op := range ops {
			if strings.Contains(op.Payer, "battlefield") {
				stats.DTrxOpCount++
			}
		}
	}
}

func adjustDeepMindFeatureOpsStats(block *hlog.Block, stats *ReferenceStats) {
	for _, ops := range block.FeatureOps {
		for range ops {
			stats.FeatureOpCount++
		}
	}
}

func adjustDeepMindPermOpsStats(block *hlog.Block, stats *ReferenceStats) {
	for _, ops := range block.PermOps {
		for range ops {
			stats.PermOpCount++
		}
	}
}

func adjustDeepMindRAMOpsStats(block *hlog.Block, stats *ReferenceStats) {
	for _, ops := range block.RAMOps {
		for _, op := range ops {
			if strings.Contains(op.Payer, "battlefield") {
				stats.RAMOpCount++
			}
		}
	}
}

func adjustDeepMindRAMCorrectionOpsStats(block *hlog.Block, stats *ReferenceStats) {
	for _, ops := range block.RAMCorrectionOps {
		for _, op := range ops {
			if strings.Contains(op.Payer, "battlefield") {
				stats.RAMCorrectionOpCount++
			}
		}
	}
}

func adjustDeepMindRLimitOpsStats(block *hlog.Block, stats *ReferenceStats) {
	for _, ops := range block.RLimitOps {
		for range ops {
			stats.RLimitOpCount++
		}
	}
}

func adjustDeepMindTableOpsStats(block *hlog.Block, stats *ReferenceStats) {
	for _, ops := range block.TableOps {
		for range ops {
			stats.TableOpCount++
		}
	}
}

func getOrderedRAMOps(block *hlog.Block) []*hlog.RAMOp {
	ramOps := []*hlog.RAMOp{}
	for _, transactionID := range getOrderedTransactionIDs(block) {
		ramOps = append(ramOps, block.RAMOps[hlog.TransactionID(transactionID)]...)
	}

	return ramOps
}

func getOrderedTransactionIDs(block *hlog.Block) []string {
	return block.TransactionIDs()
}

type ReferenceStats = struct {
	TransactionCount      int64
	CreationTreeNodeCount int64
	DBOpCount             int64
	DTrxOpCount           int64
	FeatureOpCount        int64
	PermOpCount           int64
	RAMOpCount            int64
	RAMCorrectionOpCount  int64
	RLimitOpCount         int64
	TableOpCount          int64
}
