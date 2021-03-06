module.exports = (env, callback) ->

  utils = env.utils
  path  = require 'path'
  _     = require 'underscore'

  MarkdownPage      = env.plugins.MarkdownPage
  ContentTree       = env.ContentTree
  ContentPlugin     = env.ContentPlugin
  apply_shortcodes  = env.plugins.apply_shortcodes

  marked            = require 'marked'
  marked.setOptions env.config.markdown or {}

  nest = (tree) ->
    ### Return all the items in the *tree* as an array of content plugins. ###
    index = tree[ 'index.md' ]
    index.topics = []
    for key, value of tree
      if key == 'index.md'
        # skip
      else if value instanceof ContentTree
        index.topics.push nest value
      else if value instanceof OnePagerPage
        index.topics.push value
      else
        # skip
    return index

  onePagerView = (env, locals, contents, templates, callback) ->
    ### Behaves like templateView but allso adds topics to the context ###

    if @template == 'none'
      return callback null, null

    template = templates[@template]
    if not template?
      callback new Error "page '#{ @filename }' specifies unknown template '#{ @template }'"
      return

    @setTopics()

    ctx =
      env: env
      page: this
      contents: contents
      breadcrumbs: @getBreadcrumbs( contents )

    env.utils.extend ctx, locals

    template.render ctx, callback

  class OnePagerPage extends MarkdownPage
    directory: null
    topics: []

    constructor: ( @filepath, @metadata, @markdown ) ->
      @directory = path.dirname( @filepath.full )

    getView: -> 'onepager'

    setTopics: ->
      ContentTree.fromDirectory env, @directory, ( err, tree ) =>
        tree = nest tree
        @topics = tree.topics

    @property 'html', 'getHtml'
    getHtml: (base=env.config.baseUrl) ->
      rendered = super base
      return env.plugins.apply_shortcodes.call @, rendered

    @property 'description', 'getDescription'
    getDescription: ->
      if @metadata.description then @metadata.description

    @property 'tags', ->
      if @metadata.tags then @metadata.tags

    @property 'arguments', 'getArguments'
    getArguments: ->
      if @metadata.arguments? then return @metadata.arguments else return false

    @property 'api_url', 'getAPIUrl'
    getAPIUrl: ->
      if @metadata.api_url then @metadata.api_url

    getBreadcrumbs: ( tree ) ->
      items = []
      item = path.dirname @filepath.relative
      while item != '.'
        items.push "/#{item}/"
        item = path.dirname item
      items.push '/'
      items.reverse()
      flat = ContentTree.flatten( tree )
      items = _.map( items, ( url ) ->
        filtered = flat.filter (page) ->
          matched = page.getUrl() == url
          if matched then page.last = false
          return matched
        return filtered[0]
      )
      items[ items.length - 1 ].last = true
      return items

  OnePagerPage.fromFile = (args...) ->
    MarkdownPage.fromFile.apply(this, args)

  env.helpers.breadcrumbText = ( page ) ->
    if page.metadata && page.metadata.breadcrumb
      page.metadata.breadcrumb
    else
      page.metadata.title

  env.registerContentPlugin 'topics', 'cheatsheet/**/*.*(markdown|mkd|md)', OnePagerPage

  # register the template view used by the page plugin
  env.registerView 'onepager', onePagerView

  env.plugins.OnePagerPage = OnePagerPage

  env.helpers.nest = nest
  env.helpers.marked = marked

  callback()