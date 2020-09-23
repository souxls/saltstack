/web/test:
  file.recurse:
    - source: salt://templates/test
    - exclude_pat: E@(APPDATA)|(TEMPDATA)
    - include_empty: True
