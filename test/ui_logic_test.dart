import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/format.dart';
import 'package:matchup/ui/mu_password_field.dart';
import 'package:matchup/ui/mu_phone_field.dart';

TextEditingValue _type(String text) => MuPhoneFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)),
    );

void main() {
  group('MuPhoneFormatter', () {
    test('groups 2-3-3 as the player types', () {
      expect(_type('2').text, '2');
      expect(_type('201').text, '20 1');
      expect(_type('201234').text, '20 123 4');
      expect(_type('20123456').text, '20 123 456');
    });

    test('ignores non-digits and a 9th digit', () {
      expect(_type('20a12-3456').text, '20 123 456');
      expect(_type('201234567').text, '20 123 456');
    });

    test('accepts pasted numbers with the country code', () {
      expect(_type('+216 20 123 456').text, '20 123 456');
      expect(_type('0021620123456').text, '20 123 456');
    });

    test('keeps the caret after the same digit', () {
      final v = MuPhoneFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '201234', selection: TextSelection.collapsed(offset: 3)),
      );
      expect(v.text, '20 123 4');
      expect(v.selection.baseOffset, 4); // after « 20 1 »
    });

    test('digitsOf returns the raw 8 digits', () {
      expect(MuPhoneFormatter.digitsOf('20 123 456'), '20123456');
    });
  });

  group('passwordScore', () {
    test('empty is 0, under 8 characters is always Faible', () {
      expect(passwordScore(''), 0);
      expect(passwordScore('Ab1!'), 1);
    });

    test('adds a point per criterion', () {
      expect(passwordScore('abcdefgh'), 1);
      expect(passwordScore('Abcdefgh'), 2);
      expect(passwordScore('Abcdefg1'), 3);
      expect(passwordScore('Abcdef1!'), 4);
    });

    test('standard rules', () {
      expect(MuPasswordRules.allMet('Abcdefg1'), isTrue);
      expect(MuPasswordRules.allMet('abcdefg1'), isFalse);
    });
  });

  group('format', () {
    test('levels use a comma and a band', () {
      expect(formatLevel(3.5), '3,5');
      expect(formatLevel(4), '4,0');
      expect(levelBand(2.4), 'Débutant');
      expect(levelBand(2.5), 'Intermédiaire');
      expect(levelBand(4.0), 'Avancé');
      expect(levelBand(5.5), 'Expert');
    });

    test('phone and initials', () {
      expect(formatPhone('20123456'), '+216 20 123 456');
      expect(initialsOf('Nour A.'), 'NA');
      expect(initialsOf('Nour A.', short: true), 'N');
    });
  });
}
