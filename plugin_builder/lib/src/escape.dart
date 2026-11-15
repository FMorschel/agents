/// [value] as a double-quoted YAML scalar.
String yamlString(String value) =>
    '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
