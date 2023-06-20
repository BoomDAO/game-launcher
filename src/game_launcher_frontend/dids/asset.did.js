export const idlFactory = ({ IDL }) => {
  const List = IDL.Rec();
  const Trie = IDL.Rec();
  const ClearArguments = IDL.Record({});
  const BatchId = IDL.Nat32;
  const Key = IDL.Text;
  const ChunkId = IDL.Nat32;
  const Result_3 = IDL.Variant({ ok: IDL.Null, err: IDL.Text });
  const CreateAssetArguments = IDL.Record({
    key: Key,
    content_type: IDL.Text,
  });
  const UnsetAssetContentArguments = IDL.Record({
    key: Key,
    content_encoding: IDL.Text,
  });
  const DeleteAssetArguments = IDL.Record({ key: Key });
  const SetAssetContentArguments = IDL.Record({
    key: Key,
    sha256: IDL.Opt(IDL.Vec(IDL.Nat8)),
    chunk_ids: IDL.Vec(ChunkId),
    content_encoding: IDL.Text,
  });
  const BatchOperationKind = IDL.Variant({
    CreateAsset: CreateAssetArguments,
    UnsetAssetContent: UnsetAssetContentArguments,
    DeleteAsset: DeleteAssetArguments,
    SetAssetContent: SetAssetContentArguments,
    Clear: ClearArguments,
  });
  const CommitBatchArguments = IDL.Record({
    batch_id: BatchId,
    operations: IDL.Vec(BatchOperationKind),
  });
  const Branch = IDL.Record({
    left: Trie,
    size: IDL.Nat,
    right: Trie,
  });
  const Hash = IDL.Nat32;
  const Key__1 = IDL.Record({ key: IDL.Text, hash: Hash });
  const AssetEncoding = IDL.Record({
    modified: IDL.Int,
    sha256: IDL.Vec(IDL.Nat8),
    certified: IDL.Bool,
    content_chunks: IDL.Vec(IDL.Vec(IDL.Nat8)),
    total_length: IDL.Nat,
  });
  List.fill(IDL.Opt(IDL.Tuple(IDL.Tuple(Key__1, AssetEncoding), List)));
  const AssocList = IDL.Opt(IDL.Tuple(IDL.Tuple(Key__1, AssetEncoding), List));
  const Leaf = IDL.Record({ size: IDL.Nat, keyvals: AssocList });
  Trie.fill(IDL.Variant({ branch: Branch, leaf: Leaf, empty: IDL.Null }));
  const Asset = IDL.Record({ encodings: Trie, content_type: IDL.Text });
  const Result_2 = IDL.Variant({ ok: Asset, err: IDL.Text });
  const Result_1 = IDL.Variant({ ok: AssetEncoding, err: IDL.Text });
  const Chunk = IDL.Record({
    content: IDL.Vec(IDL.Nat8),
    batch_id: BatchId,
  });
  const Result = IDL.Variant({ ok: Chunk, err: IDL.Text });
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    url: IDL.Text,
    method: IDL.Text,
    body: IDL.Vec(IDL.Nat8),
    headers: IDL.Vec(HeaderField),
  });
  const StreamingCallbackToken = IDL.Record({
    key: IDL.Text,
    sha256: IDL.Opt(IDL.Vec(IDL.Nat8)),
    index: IDL.Nat,
    content_encoding: IDL.Text,
  });
  const StreamingCallbackHttpResponse = IDL.Record({
    token: IDL.Opt(StreamingCallbackToken),
    body: IDL.Vec(IDL.Nat8),
  });
  const StreamingStrategy = IDL.Variant({
    Callback: IDL.Record({
      token: StreamingCallbackToken,
      callback: IDL.Func(
        [StreamingCallbackToken],
        [StreamingCallbackHttpResponse],
        ["query"],
      ),
    }),
  });
  const HttpResponse = IDL.Record({
    body: IDL.Vec(IDL.Nat8),
    headers: IDL.Vec(HeaderField),
    streaming_strategy: IDL.Opt(StreamingStrategy),
    status_code: IDL.Nat16,
  });
  const Time = IDL.Int;
  const AssetEncodingDetails = IDL.Record({
    modified: Time,
    sha256: IDL.Opt(IDL.Vec(IDL.Nat8)),
    length: IDL.Nat,
    content_encoding: IDL.Text,
  });
  const AssetDetails = IDL.Record({
    key: Key,
    encodings: IDL.Vec(AssetEncodingDetails),
    content_type: IDL.Text,
  });
  const Path = IDL.Text;
  const Contents = IDL.Vec(IDL.Nat8);
  return IDL.Service({
    authorize: IDL.Func([IDL.Principal], [], []),
    clear: IDL.Func([ClearArguments], [], []),
    commit_asset_upload: IDL.Func(
      [BatchId, Key, IDL.Text, IDL.Vec(ChunkId), IDL.Text, IDL.Text],
      [Result_3],
      [],
    ),
    commit_batch: IDL.Func([CommitBatchArguments], [], []),
    create_batch: IDL.Func([], [IDL.Record({ batch_id: BatchId })], []),
    create_chunk: IDL.Func(
      [IDL.Record({ content: IDL.Vec(IDL.Nat8), batch_id: BatchId })],
      [IDL.Record({ chunk_id: ChunkId })],
      [],
    ),
    cycleBalance: IDL.Func([], [IDL.Nat], ["query"]),
    get: IDL.Func(
      [IDL.Record({ key: Key, accept_encodings: IDL.Vec(IDL.Text) })],
      [
        IDL.Record({
          content: IDL.Vec(IDL.Nat8),
          sha256: IDL.Opt(IDL.Vec(IDL.Nat8)),
          content_type: IDL.Text,
          content_encoding: IDL.Text,
          total_length: IDL.Nat,
        }),
      ],
      ["query"],
    ),
    getAsset: IDL.Func([IDL.Text], [Result_2], ["query"]),
    getCaller: IDL.Func([], [IDL.Principal], []),
    getEncoding: IDL.Func([IDL.Text], [Result_1], ["query"]),
    get_chunk: IDL.Func(
      [IDL.Record({ batch: BatchId, index: IDL.Nat32 })],
      [Result],
      ["query"],
    ),
    http_request: IDL.Func([HttpRequest], [HttpResponse], ["query"]),
    http_request_streaming_callback: IDL.Func(
      [StreamingCallbackToken],
      [StreamingCallbackHttpResponse],
      ["query"],
    ),
    list: IDL.Func([IDL.Record({})], [IDL.Vec(AssetDetails)], ["query"]),
    retrieve: IDL.Func([Path], [Contents], ["query"]),
  });
};
export const init = ({ IDL }) => {
  return [];
};
