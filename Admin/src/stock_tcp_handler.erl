-module(stock_tcp_handler).
-include("../include/stockapp.hrl").
-compile(export_all).

start(_,_)->
    AppPid = spawn(?MODULE,init,[[]]),
    register(tcp_shandler, AppPid),
    {ok, AppPid}.

init(State)->
    ets:new(stock_table,[set,public,named_table,{keypos,#stocktrend.fla}]),
    loop(State).

loop(State)->
    receive
	{add_stock,Stock} ->
	    self() ! {spawn_stock,Stock},
	    StockTrend = #stocktrend{fla = Stock#stock.fla, stock_Name = Stock#stock.stock_Name},
	    ets:insert(stock_table,StockTrend),
	    loop(State);
	{spawn_stock,Stock}->
	    stock_process:start(Stock),
	    loop(State);
	{list_all_Stocks} ->
	    io:format("~n~w~n",[ets:select(stock_table,[{#stocktrend{fla='$1',stock_Name='$2'}}],[],['$2'])]),
	    loop(State);
	{get_lowest_trade,Stock} ->
	    Stock#stock.fla ! {get_lowest_trade},
	    loop(State);
	{get_higest_trade,Stock} ->
	    Stock#stock.fla ! {get_higest_trade},
	    loop(State);
	{set_trade_price,Stock,Price} ->
	    [Sobj] =  ets:lookup(stock_table,Stock#stock.fla),
	    handle_trade_price_set(Sobj,Price)
end.

handle_trade_price_set(Sobj,Price) when Sobj#stocktrend.lowest > Price ->
    UpdateSobj = #stocktrend{fla=Sobj#stocktrend.fla,stock_Name=Sobj#stocktrend.stock_Name,lowest=Price,higest=Sobj#stocktrend.higest},
    ets:insert(stock_table,UpdateSobj);

handle_trade_price_set(Sobj,Price) when Sobj#stocktrend.higest < Price ->
    UpdateSobj = #stocktrend{fla=Sobj#stocktrend.fla,stock_Name=Sobj#stocktrend.stock_Name,lowest=Sobj#stocktrend.higest,higest=Price},
    ets:insert(stock_table,UpdateSobj);

handle_trade_price_set(_,_) ->
    ok.

stop(_)->
    ok.
