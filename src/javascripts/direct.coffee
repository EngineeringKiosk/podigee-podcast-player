SubscribeButtonTrigger = require('./subscribe_button_trigger.coffee')
PodigeePodcastPlayer = require('./app.coffee')
ExternalData = require('./external_data.coffee')

class Direct
  constructor: (@elem, html, scriptSrc)->
    return unless @elem

    config = @elem.getAttribute('data-configuration').replace(/(^\s+|\s+$)/g, '')
    @id = @randomId(config)
    @configuration = @getInSiteConfig(config) || {json_config: config}

    try
      @configuration.customOptions = JSON.parse(@elem.getAttribute('data-options'))
    catch
      console.debug('[Podigee Podcast Player] data-options has invalid JSON')

    @configuration.parentLocationHash = window.location.hash
    @buildPlayer(html)
    @configuration.id = @player.id
    @setupSubscribeButton()
    new PodigeePodcastPlayer("##{@playerId()}", @configuration, scriptSrc)
    @replaceElem()

  getInSiteConfig: (config) ->
    inSiteConfig = if !(config.indexOf('http') == 0) && config.match(/\./) && !config.match(/^\//)
      configSplit = config.split('.')
      tempConfig = null
      configSplit.forEach (cfg) ->
        if tempConfig == null
          tempConfig = window[cfg]
        else
          tempConfig = tempConfig[cfg]
      tempConfig
    else
      window[config]

  randomId: (string) ->
    hash = 0
    return hash if string.length == 0

    hsh = (char) =>
      return if isNaN(char)
      hash = ((hash<<5)-hash)+char
      hash = hash & hash

    hsh(string.charCodeAt(i)) for i in [0..string.length]

    return hash.toString(16).substring(1)

  buildPlayer: (html) ->
    @player = document.createElement('div')
    @player.id = @id
    @player.innerHTML = html.replace('player', @playerId())

  playerId: () =>
    "player-#{@id}"

  setupSubscribeButton: ->
    window.addEventListener 'message', ((event) =>
      try
        eventData = JSON.parse(event.data || event.originalEvent.data)
      catch
        return
      return unless eventData.id == @player.id
      return unless eventData.listenTo == 'loadSubscribeButton'
        subscribeButton = new SubscribeButtonTrigger(@player)
        subscribeButton.listen()
    ), false

  replaceElem: ->
    @player.className += @elem.className
    @elem.parentNode.replaceChild(@player, @elem)


class DirectWrapper
  constructor: () ->
    @setUpPlayers()

  origin: (elem) ->
    scriptSrc = elem.src || elem.getAttribute('src')
    unless window.location.protocol.match(/^https/)
      scriptSrc = scriptSrc.replace(/^https/, 'http')
    scriptSrc.match(/(^.*\/)/)[0].replace(/javascripts\/$/, '').replace(/\/$/, '')


  getDirectHtml: (scriptSrc) ->
    externalData = new ExternalData()
    externalData.get("#{scriptSrc}/podigee-podcast-player-direct.html")

  appendCss: (scriptSrc) ->
    path = "#{scriptSrc}/stylesheets/app-direct.css"
    style = document.createElement('link')
    style.href = path
    style.rel = 'stylesheet'
    style.type = 'text/css'
    style.media = 'all'
    document.querySelector('head').appendChild(style)

  setUpPlayers: () ->
    self = @
    document.addEventListener 'DOMContentLoaded', ->
      if !window.podigeePlayersLoaded
        window.podigeePlayersLoaded = true
        window.VERSION = Math.round((new Date()).getTime() / 1000)
        players = []
        scriptElem = document.querySelector('script.podigee-podcast-player-direct')
        elems = document.querySelectorAll('div.podigee-podcast-player-direct')

        if elems.length
          scriptSrc = self.origin(scriptElem)
          self.getDirectHtml(scriptSrc).done (html) =>
            self.appendCss(scriptSrc)
            for elem in elems
              players.push(new Direct(elem, html, scriptSrc))
            window.podigeePodcastPlayers = players

    return

new DirectWrapper()
