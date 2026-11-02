// A small TextMate grammar for classic line-numbered BASIC. Shiki ships no
// BASIC grammar, and its Visual Basic one doesn't know REM comments, so it
// colors words inside them and treats an apostrophe as the start of a comment.
export const basicGrammar = {
  name: 'basic',
  scopeName: 'source.basic',
  patterns: [
    { match: '^\\s*\\d+', name: 'constant.numeric.line-number.basic' },
    { match: '\\bREM\\b.*$', name: 'comment.line.rem.basic' },
    { match: '"[^"]*"', name: 'string.quoted.double.basic' },
    {
      match:
        '\\b(IF|THEN|ELSE|FOR|TO|STEP|NEXT|WHILE|WEND|GOTO|GOSUB|RETURN|DIM|DEF|PRINT|USING|OPEN|CLOSE|LINE|INPUT|SYSTEM|END|AND|OR|NOT|MOD)\\b',
      name: 'keyword.control.basic',
    },
    {
      match: '\\b(SQR|EXP|LOG|ABS|INT|VAL|LEN|INSTR|EOF)\\b|\\b(MID|STR|ENVIRON|LEFT|RIGHT|CHR)\\$',
      name: 'support.function.basic',
    },
    { match: '\\bFN[A-Z][A-Z0-9]*\\b', name: 'entity.name.function.basic' },
    { match: '\\b\\d+(\\.\\d+)?(E[+-]?\\d+)?\\b', name: 'constant.numeric.basic' },
  ],
};
