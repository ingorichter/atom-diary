{CompositeDisposable} = require 'atom'
{Directory} = require 'atom'
mkdirp = require 'mkdirp'
moment = require 'moment'
path = require 'path'
os = require 'os'

module.exports = AtomDiary =
  subscriptions: null

  config:
    baseDir:
      title: 'Directory for your diary files'
      description: 'atom-diary will generate new diary files here and open them as needed.  If it is a relative path, it will be interpreted as a relative to your home directory (os.homedir)'
      type: 'string'
      default: 'Diary'
    filePrefix:
      title: 'Prefix of diary files, translates to "prefix-2015-11.extension"'
      type: 'string'
      default: 'diary'
    fileExtension:
      title: 'Extension of diary files, e.g. adoc for Asciidoc'
      type: 'string'
      default: 'adoc'
    diaryLocale:
      title: 'Language of the diary file'
      description: 'If you happen to have a differen system language than your diary language, you can set you diary language here.  This affects the generation of month and day names.<br/><br/>Leave empty to use your system default locale.'
      type: 'string'
      default: ''

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-diary:add_entry':  => @add_entry()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  fileHeader: (title) ->
    """
    = #{title}
    :toc:
    :numbered!:

    """

  entryHeader: (title) ->
    """

    == #{title}


    """

  add_entry: ->
    now = moment()
    # determine current date in terms of year, month, day
    # getCreate basedir
    baseDir = path.normalize(atom.config.get('atom-diary.baseDir'))
    if !path.isAbsolute(baseDir)
      console.log 'baseDir is not absolute ' + baseDir
      baseDir = os.homedir() + path.sep + baseDir
      console.log 'baseDir converted to absolute ' + baseDir
    else
      console.log 'baseDir is absolute ' + baseDir
    baseDir = baseDir + path.sep + now.format('YYYY')
    myDir = new Directory(baseDir)
    mkdirp.sync(myDir.getRealPathSync())

    # getCreate month file
    if atom.config.get('atom-diary.diaryLocale') != ''
      now.locale(atom.config.get('atom-diary.diaryLocale'))
    console.log 'diary locale set for moments ' + now.locale()
    dayString = now.format('YYYY-MM')
    fileName = atom.config.get('atom-diary.filePrefix') + '-' + dayString + '.' + atom.config.get('atom-diary.fileExtension')
    console.log 'filename will be ' + fileName
    currentHeader = @fileHeader(now.format('MMMM YYYY'))
    currentEntry = @entryHeader(now.format('DD. MMMM, LT, dddd'))

    # open new file in atom
    console.log 'will now open file: ' + baseDir + path.sep + fileName
    atom.workspace.open(baseDir + path.sep + fileName, null).then ->
      editor = atom.workspace.getActiveTextEditor()
      editor.moveToBottom()
      # if the file is empty, insert boilerplate
      if (editor.getText().length is 0)
        editor.insertText(currentHeader)
      editor.insertText(currentEntry)
