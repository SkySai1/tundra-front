###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos Ventures SL
###

class CardController
    @.$inject = [
        "$scope",
    ]

    constructor: (@scope) ->

    getLinkParams: () ->
        lastLoadUserstoriesParams = taiga.findScope @scope, (scope) ->
            if scope && scope.ctrl
                return scope.ctrl.lastLoadUserstoriesParams

            return false

        if lastLoadUserstoriesParams
            lastLoadUserstoriesParams['status'] = @scope.vm.item.getIn(['model', 'status'])
            lastLoadUserstoriesParams['swimlane'] = @scope.vm.item.getIn(['model', 'swimlane'])

            lastLoadUserstoriesParams = _.pickBy(lastLoadUserstoriesParams, _.identity);

            ParsedLastLoadUserstoriesParams = {}
            Object.keys(lastLoadUserstoriesParams).forEach (key) ->
                ParsedLastLoadUserstoriesParams['kanban-' + key] = lastLoadUserstoriesParams[key]

            return ParsedLastLoadUserstoriesParams
        else
            return {}

    visible: (name) ->
        return @.zoom.indexOf(name) != -1

    hasTasks: () ->
        tasks = @.item.getIn(['model', 'tasks'])
        return tasks and tasks.size > 0

    getTagColor: (color) ->
        if color
            return color
        return "#A9AABC"

    hasMultipleAssignedUsers: () ->
        assignedUsers = @.item.getIn(['model', 'assigned_users'])
        return assignedUsers and assignedUsers.size > 1

    hasVisibleAttachments: () ->
        return @.item.get('images').size > 0

    toggleFold: () ->
        @.onToggleFold({id: @.item.get('id')})

    getClosedTasks: () ->
        return @.item.getIn(['model', 'tasks']).filter (task) -> return task.get('is_closed')

    closedTasksPercent: () ->
        return @.getClosedTasks().size * 100 / @.item.getIn(['model', 'tasks']).size

    getModifyPermisionKey: () ->
        return  if @.type == 'task' then 'modify_task' else 'modify_us'

    getDeletePermisionKey: () ->
        return  if @.type == 'task' then 'delete_task' else 'delete_us'

    _setVisibility: () ->
        visibility = {
            related: @.visible('related_tasks'),
            slides: @.visible('attachments')
        }

        if !_.isUndefined(@.item.get('foldStatusChanged')) && @.visible('unfold')
            # by default attachments & task are folded in level 2, see also card-unfold.jadee
            if @.zoomLevel == 2
                visibility.related = @.item.get('foldStatusChanged')
                visibility.slides = @.item.get('foldStatusChanged')
            else
                visibility.related = !@.item.get('foldStatusChanged')
                visibility.slides = !@.item.get('foldStatusChanged')

        if !@.item.getIn(['model', 'tasks']) || !@.item.getIn(['model', 'tasks']).size
            visibility.related = false

        if !@.item.get('images') || !@.item.get('images').size
            visibility.slides = false

        return visibility

    isRelatedTasksVisible: () ->
        visibility = @._setVisibility()

        return visibility.related

    isSlideshowVisible: () ->
        visibility = @._setVisibility()

        return visibility.slides

    getNavKey: () ->
        if @.type == 'task'
            return 'project-tasks-detail'
        else if @.type == 'issue'
            return 'project-issues-detail'
        else
            return 'project-userstories-detail'

angular.module('taigaComponents').controller('Card', CardController)
