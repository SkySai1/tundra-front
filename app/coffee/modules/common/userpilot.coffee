###
# Copyright (C) 2014-2020 Taiga Agile LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# File: modules/common/userpilot.coffee
###

taiga = @.taiga
module = angular.module("taigaCommon")

class UserPilotService extends taiga.Service
    @.$inject = ["$rootScope", "$window"]
    JOINED_LIMIT_DAYS = 42

    constructor: (@rootScope, @win) ->
        @.initialized = false

    initialize: ->
        if @.initialized
            return

        @rootScope.$on '$locationChangeSuccess', =>
            if (@win.userpilot)
                @win.userpilot.reload()

        @rootScope.$on "auth:refresh", (ctx, user) =>
            @.identify()

        @rootScope.$on "auth:register", (ctx, user) =>
            @.identify()

        @rootScope.$on "auth:login", (ctx, user) =>
            @.identify()

        @.initialized = true

    checkZendeskConditions: (userData) ->
        hasPaidPlan = @.hasPaidPlan(userData)
        joined = new Date(userData["date_joined"])
        is_new_user = joined > @.getJoinedLimit()
        return hasPaidPlan and is_new_user

    identify: () ->
        userInfo = @win.localStorage.getItem("userInfo") or "{}"
        userData = JSON.parse(userInfo)

        if @win.userpilot and userData["id"]
            userPilotId = @.calculateUserPilotId(userData)
            userPilotCustomer = @.prepareUserPilotCustomer(userData)
            @win.userpilot.identify(
                userPilotId,
                userPilotCustomer
            )

        if @win.zESettings and @.checkZendeskConditions(userData)
            @.updateZendeskState()

    prepareUserPilotCustomer: (data) ->
        return {
            name: data["full_name_display"],
            email: data["email"],
            created_at: Date.now(),
            taiga_id: data["id"],
            taiga_username: data["username"],
            taiga_date_joined: data["date_joined"],
            taiga_lang: data["lang"],
            taiga_max_private_projects: data["max_private_projects"],
            taiga_max_memberships_private_projects: data["max_memberships_private_projects"],
            taiga_verified_email: data["verified_email"],
            taiga_total_private_projects: data["total_private_projects"],
            taiga_total_public_projects: data["total_public_projects"],
            taiga_roles: data["roles"] && data["roles"].toString()
        }

    hasPaidPlan: (data) ->
        maxPrivateProjects = data["max_private_projects"]
        return maxPrivateProjects != 1

    calculateUserPilotId: (data) ->
        joined = new Date(data["date_joined"])

        if (joined > @.getJoinedLimit()) or @.hasPaidPlan(data)
            return data["id"]

        return 1

    getJoinedLimit: ->
        limit = new Date
        limit.setDate(limit.getDate() - JOINED_LIMIT_DAYS);
        return limit

    updateZendeskState: ->
        @win.zESettings.webWidget.chat.suppress = false
        @win.zESettings.webWidget.contactForm.suppress = false
        @win.zESettings.webWidget.helpCenter.suppress = false
        @win.zESettings.webWidget.talk.suppress = false
        @win.zESettings.webWidget.answerBot.suppress = false


module.service("$tgUserPilot", UserPilotService)
