# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class COBOL < RegexLexer
      tag 'cobol'
      filenames '*.cbl'
      mimetypes 'text/x-cobol'

      title 'Cobol'
      desc ''

      # Ada identifiers are Unicode with underscores only allowed as separators.
      ID = /\b[[:alpha:]](?:\p{Pc}?[[:alnum:]])*\b/

      # Numerals can also contain underscores.
      NUM = /\d(_?\d)*/
      XNUM = /\h(_?\h)*/
      EXP = /(E[-+]?#{NUM})?/i

      # Return a hash mapping lower-case identifiers to token classes.
      def self.idents
        @idents ||= Hash.new(Name).tap do |h|
          %w(
            ACCEPT ACCESS ADD ADDRESS ADVANCING AFTER ALL ALPHABET ALPHABETIC ALPHABETIC-LOWER ALPHABETIC-UPPER ALPHANUMERIC ALPHANUMERIC-EDITED ALSO ALTER ALTERNATE AND ANY APPLY ARE AREA AREAS ASCENDING ASSIGN AT AUTHOR BASIS BEFORE BEGINNING BINARY BLANK BLOCK BOTTOM BY CALL CANCEL CBL CD CF CH CHARACTER CHARACTERS CLASS CLASS-ID CLOCK-UNITS CLOSE COBOL CODE CODE-SET COLLATING COLUMN COM-REG COMMA COMMON COMMUNICATION COMP COMP-1 COMP-2 COMP-3 COMP-4 COMP-5 COMPUTATIONAL COMPUTATIONAL-1 COMPUTATIONAL-2 COMPUTATIONAL-3 COMPUTATIONAL-4 COMPUTATIONAL-5 COMPUTE CONFIGURATION CONTAINS CONTENT CONTINUE CONTROL CONTROLS CONVERTING COPY CORR CORRESPONDING COUNT CURRENCY DATA DATE-COMPILED DATE-WRITTEN DAY DAY-OF-WEEK DBCS DE DEBUG-CONTENTS DEBUG-ITEM DEBUG-LINE DEBUG-NAME DEBUG-SUB-1 DEBUG-SUB-2 DEBUG-SUB-3 DEBUGGING DECIMAL-POINT DECLARATIVES DELETE DELIMITED DELIMITER DEPENDING DESCENDING DESTINATION DETAIL DISPLAY DISPLAY-1 DIVIDE DIVISION DOWN DUPLICATES DYNAMIC EGCS EGI EJECT ELSE EMI ENABLE END END-ADD END-CALL END-COMPUTE END-DELETE END-DIVIDE END-EVALUATE END-IF END-INVOKE END-MULTIPLY END-OF-PAGE END-PERFORM END-READ END-RECEIVE END-RETURN END-REWRITE END-SEARCH END-START END-STRING END-SUBTRACT END-UNSTRING END-WRITE ENDING ENTER ENTRY ENVIRONMENT EOP EQUAL ERROR ESI EVALUATE EVERY EXCEPTION EXIT EXTEND EXTERNAL FALSE FD FILE FILE-CONTROL FILLER FINAL FIRST FOOTING FOR FROM FUNCTION GENERATE GIVING GLOBAL GO GOBACK GREATER GROUP HEADING HIGH-VALUE HIGH-VALUES I-O I-O-CONTROL ID IDENTIFICATION IF IN INDEX INDEXED INDICATE INHERITS INITIAL INITIALIZE INITIATE INPUT INPUT-OUTPUT INSERT INSPECT INSTALLATION INTO INVALID INVOKE IS JUST JUSTIFIED KANJI KEY LABEL LAST LEADING LEFT LENGTH LESS LIMIT LIMITS LINAGE LINAGE-COUNTER LINE LINE-COUNTER LINES LINKAGE LOCAL-STORAGE LOCK LOW-VALUE LOW-VALUES MEMORY MERGE MESSAGE METACLASS METHOD METHOD-ID MODE MODULES MORE-LABELS MOVE MULTIPLE MULTIPLY NATIVE NATIVE_BINARY NEGATIVE NEXT NO NOT NULL NULLS NUMBER NUMERIC NUMERIC-EDITED OBJECT OBJECT-COMPUTER OCCURS OF OFF OMITTED ON OPEN OPTIONAL OR ORDER ORGANIZATION OTHER OUTPUT OVERFLOW OVERRIDE PACKED-DECIMAL PADDING PAGE PAGE-COUNTER PASSWORD PERFORM PF PH PIC PICTURE PLUS POINTER POSITION POSITIVE PRINTING PROCEDURE PROCEDURE-POINTER PROCEDURES PROCEED PROCESSING PROGRAM PROGRAM-ID PURGE QUEUE QUOTE QUOTES RANDOM RD READ READY RECEIVE RECORD RECORDING RECORDS RECURSIVE REDEFINES REEL REFERENCE REFERENCES RELATIVE RELEASE RELOAD REMAINDER REMOVAL RENAMES REPLACE REPLACING REPORT REPORTING REPORTS REPOSITORY RERUN RESERVE RESET RETURN RETURN-CODE RETURNING REVERSED REWIND REWRITE RF RH RIGHT ROUNDED RUN SAME SD SEARCH SECTION SECURITY SEGMENT SEGMENT-LIMIT SELECT SELF SEND SENTENCE SEPARATE SEQUENCE SEQUENTIAL SERVICE SET SHIFT-IN SHIFT-OUT SIGN SIZE SKIP1 SKIP2 SKIP3 SORT SORT-CONTROL SORT-CORE-SIZE SORT-FILE-SIZE SORT-MERGE SORT-MESSAGE SORT-MODE-SIZE SORT-RETURN SOURCE SOURCE-COMPUTER SPACE SPACES SPECIAL-NAMES STANDARD STANDARD-1 STANDARD-2 START STATUS STOP STRING SUB-QUEUE-1 SUB-QUEUE-2 SUB-QUEUE-3 SUBTRACT SUM SUPER SUPPRESS SYMBOLIC SYNC SYNCHRONIZED TABLE TALLY TALLYING TAPE TERMINAL TERMINATE TEST TEXT THAN THEN THROUGH THRU TIME TIMES TITLE TO TOP TRACE TRAILING TRUE TYPE UNIT UNSTRING UNTIL UP UPON USAGE USE USING VALUE VALUES VARYING WHEN WHEN-COMPILED WITH WORDS WORKING-STORAGE WRITE WRITE-ONLY ZERO ZEROES ZEROS
          ).each {|w| h[w] = Keyword}
        end
      end

      state :whitespace do
        rule %r{\s+}m, Text
        rule %r{\*.*$}, Comment::Single
      end

      state :dquote_string do
        rule %r{[^"\n]+}, Literal::String::Double
        rule %r{""}, Literal::String::Escape
        rule %r{"}, Literal::String::Double, :pop!
        rule %r{\n}, Error, :pop!
      end

      state :attr do
        mixin :whitespace
        rule ID, Name::Attribute, :pop!
        rule %r{}, Text, :pop!
      end

      # Handle a dotted name immediately following a declaration keyword.
      state :decl_name do
        mixin :whitespace
        rule %r{body\b}i, Keyword::Declaration  # package body Foo.Bar is...
        rule %r{(#{ID})(\.)} do
          groups Name::Namespace, Punctuation
        end
      end

      state :root do
        mixin :whitespace

        # String literals.
        rule %r{'.'}, Literal::String::Char
        rule %r{"[^"\n]*}, Literal::String::Double, :dquote_string

        # Real literals.
        rule %r{#{NUM}\.#{NUM}#{EXP}}, Literal::Number::Float
        rule %r{#{NUM}##{XNUM}\.#{XNUM}##{EXP}}, Literal::Number::Float

        # Integer literals.
        rule %r{2#[01](_?[01])*##{EXP}}, Literal::Number::Bin
        rule %r{8#[0-7](_?[0-7])*##{EXP}}, Literal::Number::Oct
        rule %r{16##{XNUM}*##{EXP}}, Literal::Number::Hex
        rule %r{#{NUM}##{XNUM}##{EXP}}, Literal::Number::Integer
        rule %r{#{NUM}#\w+#}, Error
        rule %r{#{NUM}#{EXP}}, Literal::Number::Integer

        # Special constructs.
        rule %r{'}, Punctuation, :attr
        rule %r{<<#{ID}>>}, Name::Label

        # Operators and punctuation characters.
        rule %r{[+*/&<=>|]|-|=>|\.\.|\*\*|[:></]=|<<|>>|<>}, Operator
        rule %r{[.,:;()]}, Punctuation

        rule ID do |m|
          t = self.class.idents[m[0].downcase]
          token t
          if t == Keyword::Declaration
            push :decl_name
          end
        end

        # Flag word-like things that don't match the ID pattern.
        rule %r{\b(\p{Pc}|[[alpha]])\p{Word}*}, Error
      end
    end
  end
end
