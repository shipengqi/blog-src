---
title: Hubot实现conversation
date: 2018-02-09 13:33:03
categories: ["Node.js"]
---

[sbot-conversation](https://github.com/sactive/sbot-conversation)，是一个对[Hubot](https://github.com/hubotio/hubot)的会话实现。

<!-- more -->

[Hubot](https://github.com/hubotio/hubot)的本质就是对用户输入的信息，进行正则匹配，匹配到结果后执行对应的`callback`。但是`hubot`本身并不支持会话。

比如下面的场景：

1. 用户输入： 我要创建一个虚拟机
2. bot 回复： 请告诉我你要创建的虚机的操作系统(windows, centos, opensuse)
3. 用户输入： windows
4. bot 回复： 请告诉我你要创建的虚机的磁盘大小(1T, 500G)
5. 用户输入： 1T
6. bot 回复： Thank you, 正在创建 ...

[sbot-conversation](https://github.com/sactive/sbot-conversation)就是为了实现上面的场景。

## Installation
```bash
npm install sbot-conversation
```

## Example
```javascript
const {initManager} = require('sbot-conversation');
const DYNAMIC_SCHEMA_MOCK = {
  onCompleteMessage: 'Create user successfully!! Thanks for reporting this.',
  type: 'dynamic',
  steps: [
    {
      question: 'Start create a user \nPlease enter your user name.',
      answer: {
        type: 'text',
        validation: {
          'description': 'full name',
          'type': 'string',
          'minLength': 8
        }
      },
      required: true
    },
    {
      question: 'Please enter your user email.',
      answer: {
        type: 'text',
        validation: {
          'description': 'email address',
          'type': 'string',
          'format': 'email',
          'maxLength': 64
        }
      },
      required: true
    },
    {
      question: 'Please enter gender enum[female, male, unspecified]',
      answer: {
        type: 'choice',
        options: [
          {
            match: 'unspecified'
          },
          {
            match: 'male'
          },
          {
            match: 'female'
          }
        ]
      },
      required: false
    }
  ]
};

const JSON_SCHEMA_MOCK = {
  'type': 'object',
  'required': [
    'name'
  ],
  'properties': {
    'name': {
      'description': 'full name',
      'type': 'string',
      'minLength': 8
    }
  }
};

module.exports = function(robot) {
  let switchBoard = initManager(robot);
  robot.respond(/dynamic create user/i, msg => {
    let schema = switchBoard.initSchema('User', DYNAMIC_SCHEMA_MOCK);
    switchBoard.start(msg, 'dynamic create user', schema);
  });

  robot.respond(/create user/i, msg => {
    let schema = switchBoard.initSchema('User', JSON_SCHEMA_MOCK);
    switchBoard.start(msg, 'create user', schema);
  });
};
```

## Usage

### Create a conversation manager instance
```javascript
initManager(robot, type, callback)
```

- robot: Hubot.Robot
- type: 'user' or 'room', default 'user'.It defines if this conversation is with the whole room or with a particular user only.
If the message comes from a user (or a room) that we're having a conversation with, it will be processed as the next step in an ongoing Dialog.
- callback: The callback should be return a `Boolean`, when the return value is `true` and there is a active conversation of the user (or the room),
it will be processed as the next step in an ongoing Dialog.

#### example
```javascript
  let switchBoard = initManager(robot, 'room', function(msg) {
    let reg = new RegExp(`^@hubot (show conversation|cancel conversation|resume conversation)(.*)`, 'i');
    if (reg.test(msg.text)) {
      return false;
    }
    return true;
  });
```

### Create a conversation

There are there patterns to create a conversation.

#### First pattern: Init a json schema

**Example**
```javascript
const JSON_SCHEMA_MOCK = {
  'type': 'object',
  'required': [
    'name',
    'email'
  ],
  'properties': {
    'name': {
      'description': 'full name',
      'type': 'string',
      'minLength': 8
    },
    'email': {
      'description': 'email address',
      'type': 'string',
      'format': 'email',
      'maxLength': 64
    },
    'employeeNum': {
      'description': 'employee Number',
      'type': 'integer',
      'minimum': 100,
      'maximum': 600
    },
    'gender': {
      'description': 'gender',
      'type': 'enum',
      'default': 'unspecified',
      'enum': [
        'unspecified',
        'male',
        'female'
      ]
    }
  }
};

module.exports = function(robot) {
  let switchBoard = initManager(robot);
  robot.respond(/create user/i, msg => {
    let schema = switchBoard.initSchema('User', JSON_SCHEMA_MOCK);
    switchBoard.start(msg, 'create user', schema);
  });
};
```

How to define a json schema, please refer[JSON Schema](http://json-schema.org/)
**`type` is required and must be a string 'object'.**

#### Second pattern: Init a dynamic message model

```javascript
const DYNAMIC_SCHEMA_MOCK = {
  onCompleteMessage: 'Create user successfully!! Thanks for reporting this.',
  type: 'dynamic',
  steps: [
    {
      question: 'Start create a user \nPlease enter your user name.',
      answer: {
        type: 'text',
        validation: {
          'description': 'full name',
          'type': 'string',
          'minLength': 8
        }
      },
      required: true
    },
    {
      question: 'Please enter your user email.',
      answer: {
        type: 'text',
        validation: {
          'description': 'email address',
          'type': 'string',
          'format': 'email',
          'maxLength': 64
        }
      },
      required: true
    },
    {
      question: 'Please enter employee Num.',
      answer: {
        type: 'text',
        validation: {
          'description': 'employee Number',
          'type': 'integer',
          'minimum': 100,
          'maximum': 600
        }
      },
      required: false
    },
    {
      question: 'Please enter gender enum[female, male, unspecified]',
      answer: {
        type: 'choice',
        options: [
          {
            match: 'unspecified'
          },
          {
            match: 'male'
          },
          {
            match: 'female'
          }
        ]
      },
      required: false
    }
  ]
};

module.exports = function(robot) {
  let switchBoard = initManager(robot);
  robot.respond(/dynamic create user/i, msg => {
    let schema = switchBoard.initSchema('User', DYNAMIC_SCHEMA_MOCK);
    switchBoard.start(msg, 'dynamic create user', schema);
  });
};
```
How to define a dynamic message model:
- onCompleteMessage: String // reply sent to the user when the conversation is done (optional)
- skipKeyword: String // default 'skip', a keyword that can be used to skip non-required questions (optional)
- skipMessage: String // a message that can be appended to any non-required questions (optional)
- type: "dynamic" // conversation schema type must be 'dynamic' (required)
- steps: Array, define properties.
```javascript
steps: [
    {
      question: String // question to ask the user (required)
      answer: {
        type: String // could be 'choice', 'text' (required)
        options: [ // add the options object if the `type` of answer is `choice`
          {
            match: String, // what robot should listen to - can be a regex
            validation: Object // validate input, refer json shcema (optional)
          }
        ]
      },
      required: Boolean
    }
  ]
```

#### Third pattern: custom
```javascript
//example

let conversation = switchBoard.start(msg, 'create user(custom)')

const function1 = (message) => {
  conversation.updateAnswers('yes')
  message.reply('Please enter your user name.')
  conversation.updateQuestion('Please enter your user name.')
  conversation.addChoice(/.*/i, function2)
}

const function2 = (message) => {
  conversation.updateAnswers(message.message.text)
  message.reply("Please enter your user email.")
  conversation.updateQuestion("Please enter your user email.")
  conversation.addChoice(/.*/i, function3)
}

const function3 = (message) => {
  conversation.updateAnswers(message.message.text)
  message.reply("Please enter employee Num.")
  conversation.updateQuestion("Please enter employee Num.")
  conversation.addChoice(/.*/i, function4)
}

const function4 = (message) => {
  conversation.updateAnswers(message.message.text)
  message.reply('Create user successfully!! Thanks for reporting this.')
  conversation.emit 'end'
}

const function5 =  (message) => {
  conversation.emit 'end'
  message.reply('Bye bye!')
}

msg.reply("Start create a user \n [yes]or [no]?")
conversation.updateQuestion("Start create a user \n [yes]or [no]?")
conversation.addChoice(/yes/i, function1)
conversation.addChoice(/no/i, function5)

```

具体的还是参考我在 [Github 的文档](https://github.com/sactive/sbot-conversation/wiki)。
