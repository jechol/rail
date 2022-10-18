# Used by "mix format"
locals_without_parens = [
  rail: 1,
  rail: 2,
  railp: 2
]

[
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
