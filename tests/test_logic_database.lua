return function(context)
    require("tests.test_logic_database_state")(context)
    require("tests.test_logic_database_retention")(context)
end
