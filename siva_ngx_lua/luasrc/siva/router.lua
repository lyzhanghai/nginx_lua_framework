#!/usr/bin/env lua
-- -*- lua -*-
-- Copyright 2015 siva Inc.
-- Author : fuhao 
--
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
--


module('siva.router',package.seeall)

local functional = require 'siva.functional'
local vars = require 'siva.vars'
local util = require 'siva.util'

local string_match = string.match
local table_insert = table.insert
local table_sort   = table.sort

function route_sorter(luri, ruri)
    if #luri==#ruri then
        return luri < ruri
    else
        return #luri > #ruri
    end
end

function _map(route_table, route_order, uri, func_name)
    local mod_name, fn = string_match(func_name, '^(.+)%.([^.]+)$')
    mod = require(mod_name)
    local func = mod[fn]
    if func then
        route_table[uri] = func
        table_insert(route_order, uri)
        -- table_sort(route_order, route_sorter) -- sort when merge!
    else
        local error_info = "SIVA_NGX_LUA URL Mapping Error:[" .. uri .. "=>" .. func_name .. "] function or controller not found in module: " .. mod_name
        logger:error(error_info)
        ngx.log(ngx.ERR, error_info)
    end
end

function map(route_table, route_order, uri, func_name)
    local ret, err = pcall(_map, route_table, route_order, uri, func_name)
    if not ret then
        local error_info = "SIVA_NGX_LUA URL Mapping Error:[" .. uri .. "=>" .. func_name .. "] " .. err
        logger:e(error_info)
        ngx.log(ngx.ERR, error_info)
    end
end

function setup()
    local app_name = getfenv(2).__CURRENT_APP_NAME__
    local main_app = getfenv(2).__MAIN_APP_NAME__
    if app_name ~= main_app then
        app_name = main_app .. ">" .. app_name
    end
    if not vars.get(app_name,"ROUTE_INFO") then
        vars.set(app_name,"ROUTE_INFO",{})
    end
    if not vars.get(app_name,"ROUTE_INFO")['ROUTE_MAP'] then
        vars.get(app_name,"ROUTE_INFO")['ROUTE_MAP'] = {}
        vars.get(app_name,"ROUTE_INFO")['ROUTE_ORDER'] = {}
    end
    vars.get(app_name, "ROUTE_INFO").logger = getfenv(2).__LOGGER
    vars.get(app_name, "ROUTE_INFO")['map'] = functional.curry(
        map,
        vars.get(app_name,"ROUTE_INFO")['ROUTE_MAP'],
        vars.get(app_name,"ROUTE_INFO")['ROUTE_ORDER']
    )
        
    -- siva.vars.get(app_name,"ROUTE_INFO")['get_config'] = functional.curry(
    --    siva.util.get_config,
    --    getfenv(2).__CURRENT_APP_NAME__
    -- )

    vars.get(app_name,"ROUTE_INFO")['get_config'] = util.get_config
        
    setfenv(2, vars.get(app_name, "ROUTE_INFO"))
end

function merge_routings(main_app, subapps)
    local main_routings=vars.get(main_app,"ROUTE_INFO")['ROUTE_MAP']
    local main_routings_order=vars.get(main_app,"ROUTE_INFO")['ROUTE_ORDER']
    for k,_ in pairs(subapps) do
        local expanded_key = main_app .. ">" .. k
        local sub_routings=vars.get(expanded_key,"ROUTE_INFO")['ROUTE_MAP']
        for sk,sv in pairs(sub_routings) do main_routings[sk]=sv end
        local sub_routings_order=vars.get(expanded_key,"ROUTE_INFO")['ROUTE_ORDER']
        for _,sv in ipairs(sub_routings_order) do table_insert(main_routings_order,sv) end
    end
    table_sort(main_routings_order, route_sorter)
end

