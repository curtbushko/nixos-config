return {
  {
    "robitx/gp.nvim",
    config = function()
      require("gp").setup({
        hooks = {
          Explain = function(gp, params)
            local template = "I have the following code from {{filename}}:\n\n"
              .. "```{{filetype}}\n{{selection}}\n```\n\n"
              .. "Please respond by explaining the code above."
            local agent = gp.get_chat_agent()
            gp.Prompt(params, gp.Target.popup, nil, agent.model, template, agent.system_prompt)
          end,
          GoCleanup = function(gp, params)
            local template = "I have the following golang code from {{filename}}:\n\n"
              .. "```{{filetype}}\n{{selection}}\n```\n\n"
              .. "Please cleanup code. Use early return/guard pattern to avoid excessive nesting and follow idomatic go practices"
            local agent = gp.get_chat_agent()
            gp.Prompt(params, gp.Target.enew("markdown"), nil, agent.model, template, agent.system_prompt)
          end,

          GoReviewCode = function(gp, params)
            local template = "I have the following golang code from {{filename}}:\n\n"
              .. "```{{filetype}}\n{{selection}}\n```\n\n"
              .. "Please analyze for code smells and suggest improvements."
            local agent = gp.get_chat_agent()
            gp.Prompt(params, gp.Target.enew("markdown"), nil, agent.model, template, agent.system_prompt)
          end,
          GoUnitTests = function(gp, params)
            local args = params.args
            local template = "I have the following golang code from {{filename}}:\n\n"
              .. "```{{filetype}}\n{{selection}}\n```\n\n"
              .. "Please respond by writing tests for the code above using table tests and the testify package"
              .. args
            local agent = gp.get_command_agent()
            gp.Prompt(params, gp.Target.enew, nil, agent.model, template, agent.system_prompt)
          end,
        },
      })
      local function keymapOptions(desc)
        return {
          noremap = true,
          silent = true,
          nowait = true,
          desc = "GPT prompt " .. desc,
        }
      end
    end,
    keys = {
      { "<leader>oc", "<CMD>GpChatNew tabnew<CR>", desc = "chat tab" },
      { "<leader>or", "<CMD>GpChatRespond<CR>", desc = "respond" },
      { "<leader>ot", "<CMD>GpChatToggle tabnew<CR>", desc = "toggle chat tab" },
      { "<leader>of", "<CMD>GpChatFinder<CR>", desc = "find chat" },
      { "<leader>ogc", "<CMD>GpGoCleanup<CR>", desc = "cleanup" },
      { "<leader>ogu", "<CMD>GpGoUnitTests<CR>", desc = "unit tests" },
      { "<leader>ogr", "<CMD>GpGoReviewCode<CR>", desc = "review code" },
      { "<leader>ox", "<CMD>GpExplain<CR>", desc = "explain code" },

      { "<leader>onv", "<CMD>GpChatNew vsplit<CR>", desc = "new chat vsplit" },
      { "<leader>ons", "<CMD>GpChatNew split<CR>", desc = "new chat split" },
      { "<leader>ont", "<CMD>GpChatNew tabnew<CR>", desc = "new chat tab" },
      { "<leader>onp", "<CMD>GpChatNew popup<CR>", desc = "new chat popup" },

      { "<leader>odr", "<CMD>GpRewrite<CR>", desc = "rewrite general" },
      { "<leader>oda", "<CMD>GpAppend<CR>", desc = "append general" },
      { "<leader>oda", "<CMD>GpPrepend<CR>", desc = "prepend general" },

      { "<leader>os", "<CMD>GpStop<CR>", desc = "stop" },
    },
  },
}
