###
 * Cylonjs Raspi adaptor
 * http://cylonjs.com
 *
 * Copyright (c) 2013 The Hybrid Group
 * Licensed under the Apache 2.0 license.
###

'use strict';

require "./pwm-pin"
namespace = require 'node-namespace'

namespace "Cylon.Adaptor", ->
  class @Raspi extends Cylon.Basestar
    PINS= {
      3: { rev1: 0, rev2: 2 },
      5: { rev1: 1, rev2: 3 },
      7: 4,
      8: 14,
      10: 15,
      11: 17,
      12: 18,
      13: { rev1: 21, rev2: 27 },
      15: 22,
      16: 23,
      18: 24,
      19: 10,
      21: 9,
      22: 25,
      23: 11,
      24: 8,
      26: 7,
    }

    constructor: (opts) ->
      super
      @connection = opts.connection
      @name = opts.name
      @board = ""
      @pins = {}
      @pwmPins = {}
      @myself

    commands: ->
      ['pins', 'pinMode', 'digitalRead', 'digitalWrite', 'pwmWrite', 'servoWrite', 'firmwareName']
      #'sendI2CConfig', 'sendI2CWriteRequest', 'sendI2CReadRequest']

    connect: (callback) ->
      Logger.debug "Connecting to board '#{@name}'..."
      @connection.emit 'connect'
      (callback)(null)

      @proxyMethods @commands, @board, @myself

    disconnect: ->
      Logger.debug "Disconnecting all pins..."
      @_disconnectPins()
      Logger.debug "Disconnecting from board '#{@name}'..."
      @connection.emit 'disconnect'

    firmwareName: ->
      'Raspberry Pi'

    digitalRead: (pinNum, callback) ->
      pin = @pins[@_translatePin(pinNum)]
      if (pin?) and (pin.mode == 'r')
        pin.digitalRead(value)
      else
        pin = @_setupDigitalPin(pin, pinNum, 'r', 'digitalRead')
        pin.on('connect', (data) => pin.digitalRead(10))
        pin.connect()

      true

    digitalWrite: (pinNum, value) ->
      pin = @pins[@_translatePin(pinNum)]
      if (pin?) and (pin.mode == 'w')
        pin.digitalWrite(value)
      else
        pin = @_setupDigitalPin(pin, pinNum, 'w', 'digitalWrite')
        pin.on('connect', (data) => pin.digitalWrite(value))
        pin.connect()

      value

    pwmWrite: (pinNum, value) ->
      #if pin?
      #pin.pwmWrite(value)
      #else
      #pin = @_pwmPin(pinNum)
      #pin.on('connect', () => pin.pwmWrite(value))
      #pin.connect()

      pin = @_pwmPin(pinNum)
      pin.pwmWrite(value)

      value

    servoWrite: (pinNum, angle) ->
      #pin = @pwmPins[@_translatePin(pinNum)]
      #if pin?
      #pin.servoWrite(value)
      #else
      #pin = @_pwmPin(pinNum)
      #pin.on('connect', () => pin.servoWrite(value))
      #pin.connect()

      pin = @_pwmPin(pinNum)
      pin.servoWrite(angle)

      value

    _pwmPin: (pinNum) ->
      gpioPinNum = @_translatePin(pinNum)
      @pwmPins[gpioPinNum] = new Cylon.IO.PwmPin(pin: gpioPinNum) unless @pwmPins[gpioPinNum]?
      @pwmPins[gpioPinNum]

    _digitalPin: (pinNum, mode) ->
      gpioPinNum = @_translatePin(pinNum)
      @pins[gpioPinNum] = new Cylon.IO.DigitalPin(pin: gpioPinNum, mode: mode) unless @pins[gpioPinNum]?
      @pins[gpioPinNum]

    _setupDigitalPin: (pin, pinNum, mode, eventName) ->
       pin.close() if (pin?)
       pin = @_digitalPin(pinNum, 'w')
       pin.on(eventName, (val) => @connection.emit(eventName, val))
       pin

    _translatePin: (pinNum) ->
      PINS[pinNum]

    _disconnectPins: ->
      for key, pin of @pins
        pin.closeSync()

      for key, pin of @pwmPins
        pin.closeSync()

