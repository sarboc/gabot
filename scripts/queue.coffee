util = require 'util'
_ = require 'underscore'

module.exports = (robot) ->
  robot.brain.data.instructorQueue ?= []
  robot.brain.data.instructorQueuePops ?= []

  queueStudent = (name) ->
    robot.brain.data.instructorQueue.push
      name: name
      queuedAt: new Date()

  stringifyQueue = ->
    _.reduce robot.brain.data.instructorQueue, (reply, student) ->
      reply += "\n"
      reply += "#{student.name} at #{student.queuedAt}"
      reply
    , ""

  popStudent = ->
    robot.brain.data.instructorQueue.shift()

  robot.respond /q(ueue)? me/i, (msg) ->
    name = msg.message.user.mention_name || msg.message.user.name
    if _.any(robot.brain.data.instructorQueue, (student) -> student.name == name)
      msg.send "#{name} is already queued"
    else
      queueStudent(name)
      msg.send "Current queue is: #{stringifyQueue()}"

  robot.respond /unq(ueue)? me/i, (msg) ->
    name = msg.message.user.mention_name || msg.message.user.name
    if _.any(robot.brain.data.instructorQueue, (student) -> student.name == name)
      robot.brain.data.instructorQueue = _.filter robot.brain.data.instructorQueue, (student) ->
        student.name != name
      msg.reply "ok, you're removed from the queue."
    else
      msg.reply "you weren't in the queue."

  robot.respond /(pop )?student( pop)?/i, (msg) ->
    return unless msg.match[1]? || msg.match[2]?
    if _.isEmpty robot.brain.data.instructorQueue
      msg.send "Student queue is empty"
    else
      student = popStudent()
      student.poppedAt = new Date()
      student.poppedBy = msg.message.user.mention_name || msg.message.user.name
      robot.brain.data.instructorQueuePops.push student
      msg.reply "go help @#{student.name}, queued at #{student.queuedAt}"

  robot.respond /student q(ueue)?/i, (msg) ->
    if _.isEmpty robot.brain.data.instructorQueue
      msg.send "Student queue is empty"
    else
      msg.send stringifyQueue()

  robot.respond /empty q(ueue)?/i, (msg) ->
    if msg.message.user.mention_name == 'kyle'
      robot.brain.data.instructorQueue = []
      msg.reply "cleared the queue"

  robot.respond /q(ueue)?[ .]length/i, (msg) ->
    _.tap robot.brain.data.instructorQueue.length, (length) ->
      msg.send "Current queue length is #{length} students."

  robot.router.get "/queue/pops", (req, res) ->
    res.setHeader 'Content-Type', 'text/html'
    _.each robot.brain.data.instructorQueuePops, (student) ->
      res.write "#{student.name} queued at #{student.queuedAt} popped at #{student.poppedAt} by #{student.poppedBy || 'nobody'}<br/>"
    res.end()
