-module(resource_SUITE).

%% API
-export([
  all/0,
  init_per_suite/1,
  end_per_suite/1,
  init_per_testcase/2,
  end_per_testcase/1
]).


%% TESTS
-export([ressource_should_notify/1,
         embed_ressource_should_notify/1,
         concurrent_resource_should_notify/1
        ]).

-record(rec, { res, help }).

all() ->
  [
   ressource_should_notify,
   embed_ressource_should_notify,
   concurrent_resource_should_notify
  ].

init_per_suite(Config) ->
  Config.

end_per_suite(Config) ->
  Config.


init_per_testcase(_, Config) ->
  Config.

end_per_testcase(_Config) ->
  ok.


ressource_should_notify(_Config) ->
  Self = self(),

  Pid = spawn(fun() ->
                  resource:notify_when_destroyed(Self, {done, self()})
              end),

  receive
    {done, Pid} -> ok
  after 1000 ->
          erlang:error(no_message_received)
  end.


embed_ressource_should_notify(_Config) ->
  Self = self(),

  Pid = spawn(fun() ->
                  Rec = #rec{res=resource:notify_when_destroyed(Self, {done, self()}),
                             help="help"},
                  Rec
              end),

  receive
    {done, Pid} -> ok
  after 1000 ->
          erlang:error(no_message_received)
  end.


concurrent_resource_should_notify(_Config) ->

  Self = self(),
  Pids = [spawn(fun() -> receive {res, _Res} -> Self ! {ok, self()} end end) || _I <- lists:seq(1, 1000)],


  Pid = spawn(fun() ->
                  Rec = #rec{res=resource:notify_when_destroyed(Self, {done, self()}),
                             help="help"},
                  lists:foreach(fun(Pid) -> Pid ! {res, Rec} end, Pids)
              end),

  ok = collect(Pids),
  receive
    {done, Pid} -> ok
  after 1000 ->
          erlang:error(no_message_received)
  end.

collect([]) -> ok;
collect(Pids) ->
  receive
    {ok, Pid} -> collect(Pids -- [Pid])
  end.
