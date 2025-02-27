grammar Filter;

/**
Filter, possibly empty
**/
filter
    : expression* EOF
    ;
    
/** 
Expressions may either be a conjunction (AND) of sequences or a simple
sequence.

Note, the AND is case-sensitive.

Example: `a b AND c AND d`

The expression `(a b) AND c AND d` is equivalent to the example.
**/
expression
    : sequence (AND sequence)*
    ;

/**    
Sequence is composed of one or more whitespace (WS) separated factors.

A sequence expresses a logical relationship between 'factors' where
the ranking of a filter result may be scored according to the number
factors that match and other such criteria as the proximity of factors
to each other within a document.

When filters are used with exact match semantics rather than fuzzy
match semantics, a sequence is equivalent to AND.

Example: `New York Giants OR Yankees`

The expression `New York (Giants OR Yankees)` is equivalent to the
example.
**/
sequence
    : factor (factor)*
    ;

/**
Factors may either be a disjunction (OR) of terms or a simple term.

Note, the OR is case-sensitive.

Example: `a < 10 OR a >= 100`
**/
factor
    : term (OR term)*
    ;

/**    
Terms may either be unary or simple expressions.

Unary expressions negate the simple expression, either mathematically `-`
or logically `NOT`. The negation styles may be used interchangeably.

Note, the `NOT` is case-sensitive and must be followed by at least one
whitespace (WS).

Examples:
* logical not     : `NOT (a OR b)`
* alternative not : `-file:".java"`
* negation        : `-30`
**/
term
    : (NOT | MINUS)? simple
    ;

/**
Simple expressions may either be a restriction or a nested (composite)
expression.
**/
simple
    : restriction
    | composite
    ;
    
/**
Restrictions express a relationship between a comparable value and a
single argument. When the restriction only specifies a comparable
without an operator, this is a global restriction.

Note, restrictions are not whitespace sensitive.

Examples:
* equality         : `package=com.google`
* inequality       : `msg != 'hello'`
* greater than     : `1 > 0`
* greater or equal : `2.5 >= 2.4`
* less than        : `yesterday < request.time`
* less or equal    : `experiment.rollout <= cohort(request.user)`
* has              : `map:key`
* global           : `prod`

In addition to the global, equality, and ordering operators, filters
also support the has (`:`) operator. The has operator is unique in
that it can test for presence or value based on the proto3 type of
the `comparable` value. The has operator is useful for validating the
structure and contents of complex values.
**/
restriction
    : comparable (comparator arg)?
    ;

/**    
Comparable may either be a member or function.
**/
comparable
    : function 
    | member
    ;

/**    
Member expressions are either value or DOT qualified field references.

Example: `expr.type_map.1.type`
**/
member
    : value (DOT field)*
    ;

/**
Function calls may use simple or qualified names with zero or more
arguments.

All functions declared within the list filter, apart from the special
`arguments` function must be provided by the host service.

Examples:
* `regex(m.key, '^.*prod.*$')`
* `math.mem('30mb')`

Antipattern: simple and qualified function names may include keywords:
NOT, AND, OR. It is not recommended that any of these names be used
within functions exposed by a service that supports list filters.
**/
function
    : name (DOT name)* LPAREN argList? RPAREN
    ;

/**
Comparators supported by list filters.
**/
comparator
    : LESS_EQUALS      // <=
    | LESS_THAN        // <
    | GREATER_EQUALS   // >=
    | GREATER_THAN     // >
    | NOT_EQUALS       // !=
    | EQUALS           // =
    | HAS              // :
    ;
    
/**
Composite is a parenthesized expression, commonly used to group
terms or clarify operator precedence.

Example: `(msg.endsWith('world') AND retries < 10)`
**/
composite
    : LPAREN expression RPAREN
    ;

/**
Value may either be a TEXT or STRING.

TEXT is a free-form set of characters without whitespace (WS)
or . (DOT) within it. The text may represent a variable, string,
number, boolean, or alternative literal value and must be handled
in a manner consistent with the service's intention.

STRING is a quoted string which may or may not contain a special
wildcard `*` character at the beginning or end of the string to
indicate a prefix or suffix-based search within a restriction.
**/
value
    // Higher priority custom values for easier type conversion.
    : INTEGER
    | FLOAT
    | BOOLEAN
    | ASTERISK 
    | DURATION
    | DATETIME
    // Standard values.
    | STRING
    | TEXT
    ;

/**
Fields may be either a value or a keyword.
**/
field
    : value
    | keyword
    ;

/**
Names may either be TEXT or a keyword.
**/
name
    : TEXT
    | keyword
    ;

argList
    : arg (',' arg)*
    ;

arg
    : comparable
    | composite
    ;

keyword
    : NOT
    | AND
    | OR
    ;

/**
Lexer Rules
**/
WS : (' ' | '\t') -> skip;

AND: 'AND';
OR: 'OR';
NOT: 'NOT';

MINUS: '-';
DOT: '.';

LESS_EQUALS: '<=';
LESS_THAN: '<';
GREATER_EQUALS: '>=';
GREATER_THAN: '>';
NOT_EQUALS: '!=';
EQUALS: '=';
HAS: ':';

LPAREN: '(';
RPAREN: ')';
ASTERISK: '*';
COMMA: ',';

fragment DIGIT: '0'..'9';

INTEGER: DIGIT+;
FLOAT: DIGIT+ ('.' DIGIT+)?;
BOOLEAN: ('true' | 'false');
DURATION: DIGIT+ ('.' DIGIT+)? 's';

fragment T: ('T'|'t');
fragment Z: ('Z'|'z');
fragment PLUSMINUS: ('+'|'-');
DATETIME: QUOTE? DIGIT DIGIT DIGIT DIGIT '-' DIGIT DIGIT '-' DIGIT DIGIT T DIGIT DIGIT ':' DIGIT DIGIT ':' DIGIT DIGIT ('.' DIGIT+)? (Z | PLUSMINUS DIGIT DIGIT ':' DIGIT DIGIT)? QUOTE?;

QUOTE: ('\'' | '"');
STRING: QUOTE ASTERISK? ~('\r' | '\n' )* ASTERISK? QUOTE;
TEXT: ('a'..'z'| 'A'..'Z' | DIGIT | '_' )+;