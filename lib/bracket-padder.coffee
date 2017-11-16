{
  adviseBefore, first, invert,
  compose, last, filter,
} = require 'underscore-plus'

pairsToPad =
  '(': ')'
  '[': ']'
  '{': '}'

invertedPairsToPad =
  invert pairsToPad

pairsToUnpad =
  '( ': ' )'
  '[ ': ' ]'
  '{ ': ' }'

defaultPairs = [
  '(', ')',
  '[', ']',
  '{', '}',
  '"', "'", '`',
]

removeEscapedQuotes =
  (str) -> str.replace(/(\\"|\\')/g, '')

module.exports =
class BracketPadder
  constructor: (@editor) ->
    adviseBefore @editor, 'insertText', @insertText
    adviseBefore @editor, 'backspace', @backspace

  insertText: (text, options) =>
    return true unless text
    return true if options?.select or options?.undo is 'skip'

    openBracket = invertedPairsToPad[text]
    isClosingBracket = !!openBracket

    return true unless text is ' ' or isClosingBracket

    if @shouldPad(text)
      @editor.insertText('  ')
      @editor.moveLeft()
      return false

    if @shouldClosePair(text, openBracket)
      @editor.moveRight(2)
      return false

    true

  backspace: =>
    cursor = @editor.getCursorBufferPosition()
    previousCharacters = @getPreviousCharacters(2, cursor)
    nextCharacters = @getNextCharacters(2, cursor)

    return true unless pairsToUnpad[previousCharacters] is nextCharacters

    @editor.moveRight()
    @editor.backspace()
    @editor.backspace()
    false

  shouldPad: (character) =>
    return false unless character is ' '

    cursor = @editor.getCursorBufferPosition()
    previousCharacter = @getPreviousCharacters(1, cursor)
    nextCharacter = @getNextCharacters(1, cursor)

    return true if pairsToPad[previousCharacter] is nextCharacter

  shouldClosePair: (closeBracket, openBracket) =>
    cursor = @editor.getCursorBufferPosition()
    previousCharacters =
      removeEscapedQuotes @getPreviousCharacters(cursor.column, cursor)
    nextCharacters = @getNextCharacters(2, cursor)

    return false unless previousCharacters.includes(openBracket)

    unclosed = getUnclosedPairs(previousCharacters)
    return false unless last(unclosed) is openBracket

    return false unless first(nextCharacters) is ' '
    return true if nextCharacters.trim() is closeBracket

  getPreviousCharacters: (count, cursor) =>
    return '' unless cursor.column

    return @editor.getTextInBufferRange([
      cursor.traverse([0, -count]),
      cursor,
    ])

  getNextCharacters: (count, cursor) =>
    return @editor.getTextInBufferRange([
      cursor,
      cursor.traverse([0, count])
    ])

###
 * Filters out characters between `opening` and `closing` characters.
 * @param  {String} opening
 * @param  {String} closing
 * @return {Function}
###
removePairs = (opening, closing) -> (str) ->
  if not closing
    closing = opening

  regex = new RegExp("#{opening}([^#{opening}]*(?=#{closing}))#{closing}", 'g')
  str.replace(regex, '')

###
 * :: String -> String
###
removeClosedPairs = compose(
  removePairs("'"),
  removePairs('"'),
  removePairs('`'),
  removePairs('\\{', '\\}'),
  removePairs('\\[', '\\]'),
  removePairs('\\(', '\\)')
)

###
 * Returns any unclosed "bracket pair characters" found within `str`.
 * @param  {String} str
 * @return {Array<String>}
###
getUnclosedPairs = (str) ->
  trimmed = removeClosedPairs(str)
  return filter(trimmed, (char) -> defaultPairs.includes(char))
