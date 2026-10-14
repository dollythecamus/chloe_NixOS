{ python }:

let
  py = python.pkgs;
  # The sealed Hermes environment already supplies several transitive
  # huggingface-hub distributions. Reuse its copies to avoid duplicate packages
  # in the hermes wrapper's sealed-v-env collision check.
  sharedRuntimeDeps = [
    "click"
    "httpx"
    "packaging"
    "tqdm"
    "typing-extensions"
  ];
  huggingfaceHubSharedDeps = py.huggingface-hub.overridePythonAttrs (old: {
    # These are already part of Hermes' sealed core, so reuse that copy at
    # environment. The faster-whisper extension resolves these from Hermes'
    # base interpreter at runtime, so they must remain present in the overall
    # Hermes package but not in this extra package's closure.
    pythonRemoveDeps = sharedRuntimeDeps;
    pythonImportsCheck = [ "huggingface_hub" ];
    doCheck = false;
    dependencies = builtins.filter (dep:
      !builtins.elem (dep.pname or "") sharedRuntimeDeps)
      (old.dependencies or [ ]);
  });
  onnxruntimeSharedDeps = py.onnxruntime.overridePythonAttrs (old: {
    # ONNX Runtime's wheel declares these runtime requirements but this
    # nixpkgs derivation omits them from its dependency list. Add them explicitly.
    dependencies = (builtins.filter (dep:
      !builtins.elem (dep.pname or "") [ "packaging" "protobuf" ])
      (old.dependencies or [ ])) ++ [ py.flatbuffers ];
    pythonRemoveDeps = [ "packaging" "protobuf" ];
    pythonImportsCheck = [ ];
  });
  tokenizersWithSharedHub = py.tokenizers.overridePythonAttrs (old: {
    dependencies = map
      (dep: if (dep.pname or "") == "huggingface-hub" then huggingfaceHubSharedDeps else dep)
      (old.dependencies or [ ]);
  });
in
py.faster-whisper.overridePythonAttrs (old: {
  pythonRemoveDeps = sharedRuntimeDeps;
  # The package's isolated check lacks shared Hermes dependencies (e.g. tqdm);
  # the complete Hermes runtime supplies them and is probed after building.
  pythonImportsCheck = [ ];
  dependencies = map
    (dep:
      if (dep.pname or "") == "huggingface-hub" then huggingfaceHubSharedDeps
      else if (dep.pname or "") == "tokenizers" then tokenizersWithSharedHub
      else if (dep.pname or "") == "onnxruntime" then onnxruntimeSharedDeps
      else dep)
    (old.dependencies or [ ]);
})
