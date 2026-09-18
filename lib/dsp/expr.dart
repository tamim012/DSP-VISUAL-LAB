import 'dart:math' as math;

import 'signal.dart' show gaussRand;

typedef Ev = double Function(double n);

enum _TokType {
  num_,
  ident,
  plus,
  minus,
  star,
  slash,
  caret,
  lparen,
  rparen,
  comma,
  end,
}

class _Tok {
  final _TokType type;
  final String text;

  _Tok(this.type, this.text);
}

List<_Tok> _tokenize(String s) {
  final toks = <_Tok>[];
  var i = 0;

  while (i < s.length) {
    final c = s[i];

    if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
      i++;
      continue;
    }

    if (RegExp(r'[0-9.]').hasMatch(c)) {
      final start = i;

      while (i < s.length &&
          RegExp(r'[0-9.eE+\-]').hasMatch(s[i])) {
        if ((s[i] == '+' || s[i] == '-') &&
            !(i > start &&
                (s[i - 1] == 'e' || s[i - 1] == 'E'))) {
          break;
        }

        i++;
      }

      toks.add(
        _Tok(
          _TokType.num_,
          s.substring(start, i),
        ),
      );

      continue;
    }

    if (RegExp(r'[A-Za-z_]').hasMatch(c)) {
      final start = i;

      while (i < s.length &&
          RegExp(r'[A-Za-z0-9_]').hasMatch(s[i])) {
        i++;
      }

      toks.add(
        _Tok(
          _TokType.ident,
          s.substring(start, i),
        ),
      );

      continue;
    }

    switch (c) {
      case '+':
        toks.add(_Tok(_TokType.plus, c));
        break;

      case '-':
        toks.add(_Tok(_TokType.minus, c));
        break;

      case '*':
        toks.add(_Tok(_TokType.star, c));
        break;

      case '/':
        toks.add(_Tok(_TokType.slash, c));
        break;

      case '^':
        toks.add(_Tok(_TokType.caret, c));
        break;

      case '(':
        toks.add(_Tok(_TokType.lparen, c));
        break;

      case ')':
        toks.add(_Tok(_TokType.rparen, c));
        break;

      case ',':
        toks.add(_Tok(_TokType.comma, c));
        break;

      default:
        throw FormatException(
          'That expression has a character that isn\'t allowed: "$c".',
        );
    }

    i++;
  }

  toks.add(_Tok(_TokType.end, ''));

  return toks;
}

/// One-argument functions.
final Map<String, double Function(double)> _fn1 = {
  'u': (n) => n >= 0 ? 1 : 0,
  'step': (n) => n >= 0 ? 1 : 0,

  'd': (n) => n.abs() < 1e-9 ? 1 : 0,
  'delta': (n) => n.abs() < 1e-9 ? 1 : 0,
  'imp': (n) => n.abs() < 1e-9 ? 1 : 0,

  'r': (n) => n >= 0 ? n : 0,
  'ramp': (n) => n >= 0 ? n : 0,

  'sgn': (n) => n > 0 ? 1 : (n < 0 ? -1 : 0),
  'sign': (n) => n > 0 ? 1 : (n < 0 ? -1 : 0),

  'sinc': (x) {
    if (x.abs() < 1e-12) {
      return 1;
    }

    return math.sin(math.pi * x) / (math.pi * x);
  },

  'sin': math.sin,
  'cos': math.cos,
  'tan': math.tan,
  'exp': math.exp,
  'log': math.log,
  'ln': math.log,

  'log10': (x) => math.log(x) / math.ln10,

  'sqrt': math.sqrt,

  'abs': (x) => x.abs(),

  'floor': (x) => x.floorToDouble(),
  'ceil': (x) => x.ceilToDouble(),
  'round': (x) => x.roundToDouble(),
};

/// Two-argument functions.
final Map<String, double Function(double, double)> _fn2 = {
  'rect': (n, nn) {
    return (n >= 0 && n < nn) ? 1 : 0;
  },

  'tri': (n, nn) {
    if (n.abs() > nn) {
      return 0;
    }

    final denominator = nn == 0 ? 1 : nn;
    return 1 - n.abs() / denominator;
  },

  'pow': (a, b) => math.pow(a, b).toDouble(),

  'min': math.min,
  'max': math.max,

  'mod': (a, b) {
    if (b == 0) {
      return double.nan;
    }

    return ((a % b) + b) % b;
  },
};

const Map<String, double> _consts = {
  'pi': math.pi,
  'e': math.e,
};

class _Parser {
  final List<_Tok> toks;
  int pos = 0;

  final math.Random rng = math.Random();

  _Parser(this.toks);

  _Tok get cur => toks[pos];

  void expect(_TokType type, String what) {
    if (cur.type != type) {
      throw FormatException(
        'Expected $what. The expression isn\'t complete. '
        'Check brackets and operators (write 2*n, not 2n).',
      );
    }

    pos++;
  }

  Ev parseExpr() {
    var left = parseTerm();

    while (
        cur.type == _TokType.plus ||
        cur.type == _TokType.minus) {
      final op = cur.type;

      pos++;

      final right = parseTerm();
      final previous = left;

      if (op == _TokType.plus) {
        left = (n) => previous(n) + right(n);
      } else {
        left = (n) => previous(n) - right(n);
      }
    }

    return left;
  }

  Ev parseTerm() {
    var left = parseUnary();

    while (
        cur.type == _TokType.star ||
        cur.type == _TokType.slash) {
      final op = cur.type;

      pos++;

      final right = parseUnary();
      final previous = left;

      if (op == _TokType.star) {
        left = (n) => previous(n) * right(n);
      } else {
        left = (n) => previous(n) / right(n);
      }
    }

    return left;
  }

  Ev parseUnary() {
    if (cur.type == _TokType.minus) {
      pos++;

      final inner = parseUnary();

      return (n) => -inner(n);
    }

    if (cur.type == _TokType.plus) {
      pos++;

      return parseUnary();
    }

    return parsePower();
  }

  Ev parsePower() {
    final base = parsePrimary();

    if (cur.type == _TokType.caret) {
      pos++;

      final exponent = parseUnary();

      return (n) {
        return math.pow(
          base(n),
          exponent(n),
        ).toDouble();
      };
    }

    return base;
  }

  Ev parsePrimary() {
    if (cur.type == _TokType.num_) {
      final value = double.parse(cur.text);

      pos++;

      return (n) => value;
    }

    if (cur.type == _TokType.lparen) {
      pos++;

      final expression = parseExpr();

      expect(_TokType.rparen, ')');

      return expression;
    }

    if (cur.type == _TokType.ident) {
      final name = cur.text;

      pos++;

      if (name == 'n') {
        return (n) => n;
      }

      if (_consts.containsKey(name)) {
        final value = _consts[name]!;

        return (n) => value;
      }

      if (name == 'noise') {
        if (cur.type == _TokType.lparen) {
          pos++;
          expect(_TokType.rparen, ')');
        }

        return (n) => gaussRand(rng);
      }

      if (name == 'rand') {
        if (cur.type == _TokType.lparen) {
          pos++;
          expect(_TokType.rparen, ')');
        }

        return (n) => rng.nextDouble();
      }

      expect(_TokType.lparen, '(');

      final args = <Ev>[
        parseExpr(),
      ];

      while (cur.type == _TokType.comma) {
        pos++;

        args.add(parseExpr());
      }

      expect(_TokType.rparen, ')');

      if (args.length == 1 && _fn1.containsKey(name)) {
        final function = _fn1[name]!;
        final argument = args[0];

        return (n) => function(argument(n));
      }

      if (args.length == 2 && _fn2.containsKey(name)) {
        final function = _fn2[name]!;
        final argument0 = args[0];
        final argument1 = args[1];

        return (n) {
          return function(
            argument0(n),
            argument1(n),
          );
        };
      }

      throw FormatException(
        'Unknown name "$name". '
        'Use n, u, d, r, rect, cos, sin, exp, pi …',
      );
    }

    throw const FormatException(
      'The expression isn\'t complete. '
      'Check brackets and operators (write 2*n, not 2n).',
    );
  }
}

/// Compiles a formula string in n.
///
/// Examples:
///   0.8^n * u[n]
///   cos(pi*n/4)
///   2*sin(pi*n/6)
Ev compileExpr(String src) {
  var s = src.trim();

  if (s.isEmpty) {
    throw const FormatException(
      'Type an expression in n, e.g. 0.8^n * u[n].',
    );
  }

  s = s
      .replaceAll('−', '-')
      .replaceAll('π', 'pi')
      .replaceAll('δ', 'd')
      .replaceAll('[', '(')
      .replaceAll(']', ')');

  final tokens = _tokenize(s);
  final parser = _Parser(tokens);

  final expression = parser.parseExpr();

  if (parser.cur.type != _TokType.end) {
    throw const FormatException(
      'The expression isn\'t complete. '
      'Check brackets and operators (write 2*n, not 2n).',
    );
  }

  return expression;
}