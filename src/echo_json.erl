%%%
%%% Copyright (c) 2012 JackNyfe. All rights reserved.
%%% THIS SOFTWARE IS PROPRIETARY AND CONFIDENTIAL. DO NOT REDISTRIBUTE.
%%%
%%% vim: set ts=4 sts=4 sw=4 et:

-module(echo_json).
-export([
    append_to_json_attr/3,
    decode/1,
    digit_hex/1,
    encode/1,
    encode_noauto/1,
    equiv/2,
    get_json_attr/2,
    get_json_attr/3,
    get_json_attr_list/2,
    get_json_attr_list/3,
    get_json_attr_str/2,
    get_json_attr_str/3,
    get_json_nested_attr/2,
    get_json_nested_attr/3,
    get_json_nested_attr_str/2,
    get_json_nested_attr_str/3,
    remove_json_attr/2,
    remove_json_nested_attr/2,
    replace_json_attr/3,
    replace_json_nested_attr/3,
    unjson/1
]).

decode(X) -> rfc4627:decode(X).

digit_hex(X) -> rfc4627:digit_hex(X).

encode(X) -> rfc4627:encode(X).

encode_noauto(X) -> rfc4627:encode_noauto(X).

equiv(Obj1, Obj2) -> rfc4627:equiv(Obj1, Obj2).

% Convert JSON blob into internal representation.
unjson(JSONBlob) ->
    try rfc4627:decode(JSONBlob) of
        {ok, Obj, _} -> Obj;
        _ -> {obj, []}
    catch
        _ -> {obj, []}
    end.

get_json_attr(Key, Obj) -> get_json_attr(Key, Obj, undefined).
get_json_attr(Key, {obj, List}, Default) ->
    case proplists:get_value(Key, List, Default) of
        null -> Default;
        V -> V
    end.

get_json_attr_str(Key, Obj) ->
    get_json_attr_str(Key, Obj, "").

get_json_attr_str(Key, Obj, Default) ->
    type_utils:to_list(get_json_attr(Key, Obj, Default)).

replace_json_attr({obj, PropList}, Attr, Value) ->
    {obj, lists:keystore(Attr, 1, PropList, {Attr, Value})}.

replace_json_nested_attr([Key], Obj, Value) ->
    replace_json_attr(Obj, Key, Value);
replace_json_nested_attr([Key | Keys], Obj, Value) ->
    Attr = get_json_attr(Key, Obj, undefined),
    NewAttr = replace_json_nested_attr(Keys, Attr, Value),
    replace_json_attr(Obj, Key, NewAttr).

append_to_json_attr(Key, Obj, Value) ->
    OldValue = get_json_attr(Key, Obj, []),
    replace_json_attr(Obj, Key, [Value | OldValue]).


remove_json_attr(Key, {obj, Obj}) ->
    {obj, proplists:delete(Key, Obj)}.
remove_json_nested_attr([Key], Json) ->
    remove_json_attr(Key, Json);
remove_json_nested_attr([Key | Ks], Json) ->
    case get_json_attr(Key, Json, undefined) of
        {obj, Obj} ->
            NewAttr = remove_json_nested_attr(Ks, {obj, Obj}),
            replace_json_attr(Json, Key, NewAttr);
        _ ->
            Json
    end.

get_json_attr_list(KeyList, Obj) -> get_json_attr_list(KeyList, Obj, undefined).
get_json_attr_list(KeyList, undefined, Default) -> [Default || _Key <- KeyList];
get_json_attr_list(KeyList, Obj, Default) ->
  [get_json_attr(Key, Obj, Default) || Key <- KeyList].

get_json_nested_attr(KeyList, Obj) ->
    get_json_nested_attr(KeyList, Obj, undefined).

get_json_nested_attr([], Obj, _Default) -> Obj;
get_json_nested_attr([Key | KeyTail], Obj, Default) ->
    case get_json_attr(Key, Obj, undefined) of
        undefined -> Default;
        NewObj -> get_json_nested_attr(KeyTail, NewObj, Default)
    end.

get_json_nested_attr_str(KeyList, Obj) ->
    get_json_nested_attr_str(KeyList, Obj, undefined).

get_json_nested_attr_str(KeyList, Obj, Default) ->
    type_utils:to_list(get_json_nested_attr(KeyList, Obj, Default)).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

echo_json_test() ->

    {obj, [{"attr", ["v1", "v2"]}]} = append_to_json_attr("attr", {obj, [{"attr", ["v2"]}]}, "v1"),
    {obj, [{"attr", ["v1", "v1"]}]} = append_to_json_attr("attr", {obj, [{"attr", ["v1"]}]}, "v1"),
    {obj, [{"attr", ["v1"]}]} = append_to_json_attr("attr", {obj, []}, "v1"),

    {obj, [{"k2", "v2"}]} = remove_json_nested_attr(["k1"], {obj, [{"k1", "v1"}, {"k2", "v2"}]}),
    {obj, [{"k1", {obj, []}}]} = remove_json_nested_attr(["k1", "k11"], {obj, [{"k1", {obj, [{"k11", {obj, [{"k111", "v111"}]}}]}}]}),
    {obj, [{"k1", "v1"}]} = remove_json_nested_attr(["k2"], {obj, [{"k1", "v1"}]}),
    {obj, [{"k1", "v1"}]} = remove_json_nested_attr(["k2", "k22"], {obj, [{"k1", "v1"}]}).

-endif.
