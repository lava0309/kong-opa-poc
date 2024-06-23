package httpapi.authz

import rego.v1

import input.request.body.username

default allow = false

# Fetch username from Redis via Webdis
username_data := {
    "method": "GET",
    "url": "http://webdis:7379/GET/username",
    "headers": {"Content-Type": "application/json"}
}

response := http.send(username_data)

allow if {
    response.status_code == 200
    response.body.GET == input.request.body.username
}