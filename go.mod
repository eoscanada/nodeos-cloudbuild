module github.com/eoscanada/nodeos-cloudbuild

require (
	github.com/davecgh/go-spew v1.1.1
	github.com/eoscanada/bstream v1.6.3-0.20191001175021-c9bd5e9f672b
	github.com/eoscanada/jsonpb v0.0.0-20190926194323-1de8191ec406
	github.com/gogo/protobuf v1.2.0
	github.com/gorilla/websocket v1.4.0 // indirect
	github.com/nu7hatch/gouuid v0.0.0-20131221200532-179d4d0c4d8d // indirect
	github.com/stretchr/testify v1.4.0
)

// This is required to fix build where 0.1.0 version is not considered a valid version because a v0 line does not exists
// We replace with same commit, simply tricking go and tell him that's it's actually version 0.0.3
replace github.com/census-instrumentation/opencensus-proto v0.1.0-0.20181214143942-ba49f56771b8 => github.com/census-instrumentation/opencensus-proto v0.0.3-0.20181214143942-ba49f56771b8

go 1.13
