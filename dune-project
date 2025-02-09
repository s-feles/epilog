(lang dune 3.14)

(name epilog)

(source
 (github s-feles-/epilog))

(authors "Łukasz Janicki")

(package
 (name epilog)
 (allow_empty)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune)
 (tags
  (topics "to describe" your project)))

(generate_opam_files true)

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
