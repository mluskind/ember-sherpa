---
title: "beforeModel"
tags: [ "model", "transition", "redirect", "redirection", "retry" ]
template: index.jade
description: hook executed before resolving models ( use for early redirection )
api_url: "http://emberjs.com/api/classes/Ember.Route.html#method_beforeModel"
arguments:
    transition:
        required: false
        description: optional - promise can be used to abort or retry transition to route
---