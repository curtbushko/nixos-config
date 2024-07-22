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
					Translator = function(gp, params)
						local agent = gp.get_command_agent()
						local chat_system_prompt = "You are a Translator, please translate between English and Chinese."
						gp.cmd.ChatNew(params, agent.model, chat_system_prompt)
					end,
					CodeReview = function(gp, params)
						local template = "I have the following code from {{filename}}:\n\n"
							.. "```{{filetype}}\n{{selection}}\n```\n\n"
							.. "Please analyze for code smells and suggest improvements."
						local agent = gp.get_chat_agent()
						gp.Prompt(params, gp.Target.enew("markdown"), nil, agent.model, template, agent.system_prompt)
					end,
					UnitTests = function(gp, params)
						local args = params.args
						local template = "I have the following code from {{filename}}:\n\n"
							.. "```{{filetype}}\n{{selection}}\n```\n\n"
							.. "Please respond by writing for the code above. by using mockey.Mock. writing a UT for this funtion "
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
            { "<leader>ocnv", "<CMD>GpChatNew vsplit<CR>", desc = "new chat vsplit" },
            { "<leader>ocns", "<CMD>GpChatNew split<CR>", desc = "new chat split" },
            { "<leader>ocnt", "<CMD>GpChatNew tabnew<CR>", desc = "new chat tab" },
            { "<leader>ocnp", "<CMD>GpChatNew popup<CR>", desc = "new chat popup" },

            { "<leader>ocpv", "<CMD>GpChatPaste vsplit<CR>", desc = "paste chat vsplit" },
            { "<leader>ocps", "<CMD>GpChatPaste split<CR>", desc = "paste chat split" },
            { "<leader>ocpt", "<CMD>GpChatPaste tabnew<CR>", desc = "paste chat tab" },
            { "<leader>ocpp", "<CMD>GpChatPaste popup<CR>", desc = "paste chat popup" },

            { "<leader>octv", "<CMD>GpChatToggle vsplit<CR>", desc = "toggle chat vsplit" },
            { "<leader>octs", "<CMD>GpChatToggle split<CR>", desc = "toggle chat split" },
            { "<leader>octt", "<CMD>GpChatToggle tabnew<CR>", desc = "toggle chat tab" },
            { "<leader>octp", "<CMD>GpChatToggle popup<CR>", desc = "toggle chat popup" },

            { "<leader>ocf", "<CMD>GpChatFinder<CR>", desc = "find chat" },
            { "<leader>ocr", "<CMD>GpChatRespond<CR>", desc = "respond again" },
            { "<leader>ocd", "<CMD>GpChatDelete<CR>", desc = "delete chat" },

            { "<leader>ogr", "<CMD>GpRewrite<CR>", desc = "rewrite general" },
            { "<leader>oga", "<CMD>GpAppend<CR>", desc = "append general" },
            { "<leader>oga", "<CMD>GpPrepend<CR>", desc = "prepend general" },
            { "<leader>ogb", "<CMD>GpEnew<CR>", desc = "new general buffer" },
            { "<leader>ogs", "<CMD>GpNew<CR>", desc = "new general split" },
            { "<leader>ogv", "<CMD>GpVnew<CR>", desc = "new general vsplit" },
            { "<leader>ogt", "<CMD>GpTabnew<CR>", desc = "new general tab" },
            { "<leader>ogp", "<CMD>GpPopup<CR>", desc = "new general popup" },


            { "<leader>os", "<CMD>GpStop<CR>", desc = "stop" },

        },

	},
}
