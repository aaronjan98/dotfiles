-- Markdown snippets for LuaSnip
-- Ported from shortcuts.json (Obsidian latex-suite format)
-- Skipped: JS function snippets (pa*, iden, arr_), ${GREEK}/${SYMBOL} macros, ${VISUAL} ops

local ls   = require("luasnip")
local s    = ls.snippet
local t    = ls.text_node
local i    = ls.insert_node
local f    = ls.function_node
local rep  = require("luasnip.extras").rep

-- ── Math context detection ────────────────────────────────────────────────────
-- Walks the treesitter tree upward; falls back to counting $ signs on the line.
local function in_math()
  local ok, node = pcall(vim.treesitter.get_node)
  if ok and node then
    local n = node
    while n do
      local tp = n:type()
      if tp == "inline_formula" or tp == "math_environment"
         or tp == "displayed_formula" then
        return true
      end
      n = n:parent()
    end
    return false
  end
  -- Fallback: count unescaped $ signs before cursor on this line
  local pos  = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_buf_get_lines(0, pos[1] - 1, pos[1], false)[1] or ""
  local n    = select(2, line:sub(1, pos[2]):gsub("%$", ""))
  return n % 2 == 1
end

-- ── Snippet constructors ──────────────────────────────────────────────────────
-- ma  : math auto-trigger (string trigger)
-- mar : math auto-trigger (regex/Lua-pattern trigger)
-- ga  : global auto-trigger (fires everywhere in markdown)

local function ma(trig, nodes, opts)
  return s(vim.tbl_extend("force", {
    trig      = trig,
    condition = in_math,
  }, opts or {}), nodes)
end

local function mar(trig, nodes)
  return ma(trig, nodes, { regTrig = true, wordTrig = false })
end

local function ga(trig, nodes)
  return s({ trig = trig }, nodes)
end

-- m: math, Tab-triggered (no auto)
local function m(trig, nodes, opts)
  return s(vim.tbl_extend("force", {
    trig      = trig,
    condition = in_math,
  }, opts or {}), nodes)
end

-- ── Regular snippets (Tab-triggered) ─────────────────────────────────────────
local snips = {
  -- Math mode, no auto-trigger (option "m" without "A")
  m("df",    { t("\\dfrac{"), i(1), t("}{"), i(2), t("}"), i(3) }),
  m("it",    { t("\\mathit{"), i(1), t("}"), i(2) }),
  m("lim",   { t("\\lim_{ "), i(1, "n"), t(" \\to "), i(2, "\\infty"), t(" } "), i(3) }),
  m("to",    { t("\\to "), i(1) }),
  m("sub",   { t("\\subset") }),
  m("sup",   { t("\\supset") }),
  m("or",    { t("\\;\\lor\\;") }),
  m("and",   { t("\\;\\land\\;") }),
  m("ni",    { t("\\ni") }),
  m("tr",    { t("\\operatorname{Tr}("), i(1), t(")"), i(2) }),
  m("var",   { t("\\operatorname{Var}") }),
  m("ker",   { t("\\ker") }),
  m("dim",   { t("\\dim") }),
  m("ob",    { t("\\overbrace{ "), i(1), t(" }") }),
  m("ub",    { t("\\underbrace{ "), i(1), t(" }") }),
  m("ol",    { t("\\overline{ "), i(1), t(" }"), i(2) }),
  m("os",    { t("\\overset{ "), i(1), t(" }{ "), i(2), t(" }"), i(3) }),
  m("wts",   { t("want to show ") }),
  m("sps",   { t("Suppose ") }),
  m("wlog",  { t("without loss of generality ") }),
  m("wma",   { t("we may assume ") }),
  m("wrt",   { t("with respect to ") }),
  m("st",    { t("\\,\\text{ s.t. }\\, "), i(1) }),
  m("pmod",  { t("\\pmod{"), i(1), t("}"), i(2) }),
  m("mod",   { t("\\mod") }),

  -- Tab-triggered math environments (multiline)
  m("pmat",  { t({ "\\begin{pmatrix}", "" }), i(1), t({ "", "\\end{pmatrix}" }) }),
  m("bmat",  { t({ "\\begin{bmatrix}", "" }), i(1), t({ "", "\\end{bmatrix}" }) }),
  m("Bmat",  { t({ "\\begin{Bmatrix}", "" }), i(1), t({ "", "\\end{Bmatrix}" }) }),
  m("vmat",  { t({ "\\begin{vmatrix}", "" }), i(1), t({ "", "\\end{vmatrix}" }) }),
  m("cases", { t({ "\\begin{cases}", "" }), i(1), t({ "", "\\end{cases}" }) }),
  m("align", { t({ "\\begin{align}", "" }), i(1), t({ "", "\\end{align}" }) }),
}

-- ── Autosnippets ──────────────────────────────────────────────────────────────
local autosnips = {

  -- ── Math entry (global, option "tA") ───────────────────────────────────────
  ga("mk", { t("$"), i(1), t("$") }),
  s({ trig = "dm", snippetType = "autosnippet" }, {
    t({ "$$", "" }), i(1), t({ "", "$$" }),
  }),

  -- ── Text-mode structural (option "tA") ─────────────────────────────────────
  ga("def.",   { t("**Definition"), i(1), t(".** "), i(2) }),
  ga("thm.",   { t("**Theorem"), i(1), t(".** "), i(2) }),
  ga("lemm.",  { t("**Lemma"), i(1), t(".** "), i(2) }),
  ga("cor.",   { t("**Corollary"), i(1), t(".** "), i(2) }),
  ga("prop.",  { t("**Proposition.** ") }),
  ga("pf.",    { t("**Proof.** ") }),
  ga("ex.",    { t("**Example"), i(1), t(".** "), i(2) }),
  ga("obj.",   { t("**Objective"), i(1), t(".** "), i(2) }),
  ga("sol.",   { t("**Solution"), i(1), t(".** "), i(2) }),
  ga("case",   { t("**Case "), i(1), t(":** "), i(2) }),
  ga("nb",     { t("**N.B.**: ") }),

  -- ── Basic math operations (option "mA") ────────────────────────────────────
  ma("sr",   { t("^2") }),
  ma("cb",   { t("^3") }),
  ma("invs", { t("^{-1}") }),
  ma("conj", { t("^{*}") }),
  ma("ee",   { t("e^{ "), i(1), t(" }"), i(2) }),
  ma("sq",   { t("\\sqrt{ "), i(1), t(" }"), i(2) }),
  ma("cr",   { t("\\sqrt[3]{ "), i(1), t(" }"), i(2) }),
  ma("cq",   { t("\\sqrt["), i(1), t("]{ "), i(2), t(" }"), i(3) }),
  ma("//",   { t("\\frac{"), i(1), t("}{"), i(2), t("}"), i(3) }),
  ma("_",    { t("_{"), i(1), t("}"), i(2) }),
  ma("sts",  { t("_\\text{"), i(1), t("}") }),
  ma("bf",   { t("\\mathbf{"), i(1), t("}") }),
  ma("bb",   { t("\\mathbb{"), i(1), t("}") }),
  ma("rm",   { t("\\mathrm{"), i(1), t("}"), i(2) }),
  ma("tt",   { t("\\text{"), i(1), t("}"), i(2) }),
  ma("cal",  { t("\\mathcal{"), i(1), t("}"), i(2) }),
  ma("Re",   { t("\\mathrm{Re}") }),
  ma("Im",   { t("\\operatorname{Im}") }),
  ma("opname", { t("\\operatorname{"), i(1), t("}") }),

  -- ── Decorators with letter capture (option "rmA") ──────────────────────────
  mar("([%a])hat",   { f(function(_, snip) return "\\hat{"   .. snip.captures[1] .. "}" end) }),
  mar("([%a])bar",   { f(function(_, snip) return "\\bar{"   .. snip.captures[1] .. "}" end) }),
  mar("([%a])vec",   { f(function(_, snip) return "\\vec{"   .. snip.captures[1] .. "}" end) }),
  mar("([%a])tilde", { f(function(_, snip) return "\\tilde{" .. snip.captures[1] .. "}" end) }),
  mar("([%a])dot",   { f(function(_, snip) return "\\dot{"   .. snip.captures[1] .. "}" end) }),
  mar("([%a])ddot",  { f(function(_, snip) return "\\ddot{"  .. snip.captures[1] .. "}" end) }),
  mar("([%a])und",   { f(function(_, snip) return "\\underline{" .. snip.captures[1] .. "}" end) }),

  -- ── Decorator fallbacks (no capture) ───────────────────────────────────────
  ma("hat",   { t("\\hat{"), i(1), t("}"), i(2) }),
  ma("bar",   { t("\\bar{"), i(1), t("}"), i(2) }),
  ma("vec",   { t("\\vec{"), i(1), t("}"), i(2) }),
  ma("tilde", { t("\\tilde{"), i(1), t("}"), i(2) }),
  ma("dot",   { t("\\dot{"), i(1), t("}"), i(2) }),
  ma("ddot",  { t("\\ddot{"), i(1), t("}"), i(2) }),
  ma("und",   { t("\\underline{"), i(1), t("}"), i(2) }),
  ma("odot",  { t("\\odot") }),
  ma("cdot",  { t("\\cdot") }),

  -- ── Auto subscript: x2 → x_{2}, x12 → x_{12} (option "rmA") ───────────────
  mar("([%a])(%d)",    { f(function(_, snip) return snip.captures[1] .. "_{" .. snip.captures[2] .. "}" end) }),
  mar("([%a])_(%d%d)", { f(function(_, snip) return snip.captures[1] .. "_{" .. snip.captures[2] .. "}" end) }),

  -- ── Inverse via double dash: x-- → x^{-1} (option "rmA") ──────────────────
  mar("([%a])%-%-",  { f(function(_, snip) return snip.captures[1] .. "^{-1}" end) }),

  -- ── Named index shorthands ──────────────────────────────────────────────────
  ma("xnn", { t("x_{n}") }),
  ma("xii", { t("x_{i}") }),
  ma("xjj", { t("x_{j}") }),
  ma("xp1", { t("x_{n+1}") }),
  ma("ynn", { t("y_{n}") }),
  ma("yii", { t("y_{i}") }),
  ma("yjj", { t("y_{j}") }),

  -- ── Greek letters (option "mA", trigger "@x" or ":x") ─────────────────────
  ma("@a", { t("\\alpha") }),
  ma("@b", { t("\\beta") }),
  ma("@g", { t("\\gamma") }),
  ma("@G", { t("\\Gamma") }),
  ma("@d", { t("\\delta") }),
  ma("@D", { t("\\Delta") }),
  ma("@e", { t("\\epsilon") }),
  ma(":e", { t("\\varepsilon") }),
  ma("@z", { t("\\zeta") }),
  ma("@t", { t("\\theta") }),
  ma("@T", { t("\\Theta") }),
  ma(":t", { t("\\vartheta") }),
  ma("@i", { t("\\iota") }),
  ma("@k", { t("\\kappa") }),
  ma("@l", { t("\\lambda") }),
  ma("@L", { t("\\Lambda") }),
  ma("@s", { t("\\sigma") }),
  ma("@S", { t("\\Sigma") }),
  ma("@u", { t("\\upsilon") }),
  ma("@U", { t("\\Upsilon") }),
  ma("@o", { t("\\omega") }),
  ma("@O", { t("\\Omega") }),
  ma("ome",  { t("\\omega") }),
  ma("Ome",  { t("\\Omega") }),
  ma("Psi",  { t("\\Psi") }),
  ma("aleph",{ t("\\aleph") }),

  -- ── Symbols ─────────────────────────────────────────────────────────────────
  ma("oo",        { t("\\infty") }),
  ma("sum",       { t("\\sum") }),
  ma("prod",      { t("\\prod") }),
  ma("lim",       { t("\\lim") }),
  ma("mlim",      { t("\\lim_{ ("), i(1, "x,y"), t(") \\to ("), i(2, "0,0"), t(") } "), i(3) }),
  ma("nabla",     { t("\\nabla") }),
  ma("del",       { t("\\nabla") }),
  ma("converges", { t("\\leadsto") }),
  ma("+-",        { t("\\pm") }),
  ma("-+",        { t("\\mp") }),
  ma("..",        { t("\\dots") }),
  ma("l..",       { t("\\ldots") }),
  ma("v..",       { t("\\vdots") }),
  ma("d..",       { t("\\ddots") }),
  ma("c..",       { t("\\cdots") }),
  ma("**",        { t("\\cdot") }),
  ma("pll",       { t("\\parallel") }),
  ma("check",     { t("\\checkmark") }),
  ma("prop",      { t("\\propto") }),
  ma("tf",        { t("\\therefore") }),
  ma("quad",      { t("\\quad") }),
  ma("qq",        { t("\\qquad") }),
  ma(",,",        { t("\\,") }),
  ma(";;",        { t("\\;") }),
  ma("o+",        { t("\\oplus ") }),
  ma("oxx",       { t("\\otimes ") }),

  -- ── Comparisons ─────────────────────────────────────────────────────────────
  ma("==",  { t("\\equiv") }),
  ma("!=",  { t("\\neq") }),
  ma(">=",  { t("\\geq") }),
  ma("<=",  { t("\\leq") }),
  ma(">>",  { t("\\gg") }),
  ma("<<",  { t("\\ll") }),
  ma(":=",  { t("\\coloneqq") }),

  -- ── Arrows ──────────────────────────────────────────────────────────────────
  ma("rw",   { t("\\rightarrow ") }),
  ma("lw",   { t("\\leftarrow ") }),
  ma("lrw",  { t("\\leftrightarrow ") }),
  ma("Rw",   { t("\\Rightarrow ") }),
  ma("Lw",   { t("\\Leftarrow ") }),
  ma("Lrw",  { t("\\Longrightarrow ") }),
  ma("Llw",  { t("\\Longleftarrow ") }),
  ma("slrw", { t("\\Leftrightarrow ") }),
  ma("Dlrw", { t("\\Longleftrightarrow") }),
  ma("->",   { t("\\to") }),
  ma("!>",   { t("\\mapsto") }),
  ma("=<",   { t("\\impliedby") }),
  ma("uw",   { t("\\uparrow") }),
  ma("dw",   { t("\\downarrow") }),
  ma("udw",  { t("\\updownarrow") }),
  ma("sew",  { t("\\searrow") }),
  ma("sww",  { t("\\swarrow") }),
  ma("new",  { t("\\nearrow") }),
  ma("nww",  { t("\\nwarrow") }),
  ma("rrw",  { t("\\rightrightarrows") }),
  ma("rlw",  { t("\\rightleftarrows") }),
  ma("xrw",  { t("\\xrightarrow{"), i(1), t("} "), i(2) }),
  ma("xRw",  { t("\\xRightarrow{"), i(1), t("} "), i(2) }),
  ma("xlw",  { t("\\xleftarrow{"), i(1), t("} "), i(2) }),
  ma("orw",  { t("\\overrightarrow{ "), i(1), t(" }"), i(2) }),
  ma("olw",  { t("\\overleftarrow{ "), i(1), t(" }"), i(2) }),
  ma("pmi",  { t("\\xRightarrow{\\text{PMI}}") }),

  -- ── Set theory ───────────────────────────────────────────────────────────────
  ma("CC",    { t("\\mathbb{C}") }),
  ma("RR",    { t("\\mathbb{R}") }),
  ma("NN",    { t("\\mathbb{N}") }),
  ma("ZZ",    { t("\\mathbb{Z}") }),
  ma("QQ",    { t("\\mathbb{Q}") }),
  ma("PP",    { t("\\mathbb{P}") }),
  ma("EE",    { t("\\mathbb{E}") }),
  ma("LL",    { t("\\mathcal{L}") }),
  ma("HH",    { t("\\mathcal{H}") }),
  ma("SS",    { t("\\mathcal{S}") }),
  ma("eset",  { t("\\emptyset") }),
  ma("nothing", { t("\\varnothing") }),
  ma("-set",  { t("\\setminus") }),
  ma("sub=",  { t("\\subseteq") }),
  ma("sub!=", { t("\\subsetneq") }),
  ma("sup=",  { t("\\supseteq") }),
  ma("sup!=", { t("\\supsetneq") }),
  ma("set",   { t("\\{ "), i(1), t(" \\}"), i(2) }),
  ma("fa",    { t("\\forall") }),
  ma("te",    { t("\\exists") }),
  ma("ind",   { t("\\perp\\!\\!\\perp") }),
  ma("sim",   { t("\\sim") }),

  -- ── Brackets ─────────────────────────────────────────────────────────────────
  ma("avg",   { t("\\langle "), i(1), t(" \\rangle "), i(2) }),
  ma("norm",  { t("\\lvert "), i(1), t(" \\rvert "), i(2) }),
  ma("Norm",  { t("\\lVert "), i(1), t(" \\rVert "), i(2) }),
  ma("ceil",  { t("\\lceil "), i(1), t(" \\rceil "), i(2) }),
  ma("floor", { t("\\lfloor "), i(1), t(" \\rfloor "), i(2) }),
  ma("lr(",   { t("\\left( "), i(1), t(" \\right) "), i(2) }),
  ma("lr{",   { t("\\left\\{ "), i(1), t(" \\right\\} "), i(2) }),
  ma("lr[",   { t("\\left[ "), i(1), t(" \\right] "), i(2) }),
  ma("lr|",   { t("\\left| "), i(1), t(" \\right| "), i(2) }),
  ma("lra",   { t("\\left< "), i(1), t(" \\right> "), i(2) }),

  -- ── Math misc ────────────────────────────────────────────────────────────────
  ma("box",   { t("\\boxed{ "), i(1), t(" }") }),
  ma("qed",   { t("\\square") }),
  ma("bqed",  { t("\\blacksquare") }),
  ma("blank", { t("\\,\\underline{~~~~~~~~~~~~~~}") }),
  ma("contra",{ t("\\Rightarrow\\Leftarrow") }),
  ma("eval",  { t("\\bigg|") }),
  ma("beg",   { t("\\begin{align"), i(1), t("}\n"), i(2), t("\n\\end{align"), rep(1), t("}") }),
  ma("tayl",  { t("f(x + h) = f(x) + f'(x)h + f''(x)\\frac{h^{2}}{2!} + \\dots"), i(1) }),

  -- ── Operators ────────────────────────────────────────────────────────────────
  ma("gcd",    { t("\\gcd") }),
  ma("min",    { t("\\min") }),
  ma("max",    { t("\\max") }),
  ma("argmin", { t("\\operatorname{argmin}") }),
  ma("dom",    { t("\\operatorname{dom}("), i(1), t(") "), i(2) }),
  ma("range",  { t("\\operatorname{range}("), i(1), t(") "), i(2) }),
  ma("span",   { t("\\operatorname{span}\\{ "), i(1), t(" \\}"), i(2) }),
  ma("curl",   { t("\\operatorname{curl}") }),
  ma("lub",    { t("\\operatorname{lub} "), i(1) }),
  ma("glb",    { t("\\operatorname{glb} "), i(1) }),
  ma("power",  { t("\\mathcal{P}("), i(1), t(") "), i(2) }),

  -- Operators with trailing space in trigger to avoid substring conflicts
  s({ trig = "sup ", snippetType = "autosnippet", condition = in_math },
    { t("\\operatorname{sup} "), i(1) }),
  s({ trig = "inf ", snippetType = "autosnippet", condition = in_math },
    { t("\\operatorname{inf} "), i(1) }),

  -- ── Derivatives ──────────────────────────────────────────────────────────────
  ma("ddt",  { t("\\frac{d}{dt} ") }),
  ma("ddx",  { t("\\frac{d}{dx} ") }),
  ma("ddy",  { t("\\frac{d}{dy} ") }),
  ma("dydx", { t("\\frac{dy}{dx} ") }),
  ma("dxdy", { t("\\frac{dx}{dy} ") }),
  ma("par",  { t("\\partial") }),

  -- ── Integrals ────────────────────────────────────────────────────────────────
  s({ trig = "\\int", snippetType = "autosnippet", condition = in_math }, {
    t("\\int "), i(1), t(" \\, d"), i(2, "x"), t(" "), i(3),
  }),
  s({ trig = "\\sum", snippetType = "autosnippet", condition = in_math }, {
    t("\\sum_{"), i(1, "i"), t("="), i(2, "1"), t("}^{"), i(3, "N"), t("} "), i(4),
  }),
  s({ trig = "\\prod", snippetType = "autosnippet", condition = in_math }, {
    t("\\prod_{"), i(1, "i"), t("="), i(2, "1"), t("}^{"), i(3, "N"), t("} "), i(4),
  }),
  s({ trig = "\\lim", snippetType = "autosnippet", condition = in_math }, {
    t("\\lim_{ "), i(1, "n"), t(" \\to "), i(2, "\\infty"), t(" } "), i(3),
  }),
  ma("dint", { t("\\int_{"), i(1, "0"), t("}^{"), i(2, "1"), t("} "), i(3), t(" \\, d"), i(4, "x"), t(" "), i(5) }),
  ma("oint", { t("\\oint") }),
  ma("iint", { t("\\iint") }),
  ma("iiint",{ t("\\iiint") }),
  ma("oinf", { t("\\int_{0}^{\\infty} "), i(1), t(" \\, d"), i(2, "x"), t(" "), i(3) }),
  ma("infi", { t("\\int_{-\\infty}^{\\infty} "), i(1), t(" \\, d"), i(2, "x"), t(" "), i(3) }),

  -- ── Trig (add backslash via regex capture) ───────────────────────────────────
  mar("([^\\\\])(sin)",    { f(function(_, snip) return snip.captures[1] .. "\\sin"    end) }),
  mar("([^\\\\])(cos)",    { f(function(_, snip) return snip.captures[1] .. "\\cos"    end) }),
  mar("([^\\\\])(tan)",    { f(function(_, snip) return snip.captures[1] .. "\\tan"    end) }),
  mar("([^\\\\])(arcsin)", { f(function(_, snip) return snip.captures[1] .. "\\arcsin" end) }),
  mar("([^\\\\])(arccos)", { f(function(_, snip) return snip.captures[1] .. "\\arccos" end) }),
  mar("([^\\\\])(arctan)", { f(function(_, snip) return snip.captures[1] .. "\\arctan" end) }),
  mar("([^\\\\])(sec)",    { f(function(_, snip) return snip.captures[1] .. "\\sec"    end) }),
  mar("([^\\\\])(cot)",    { f(function(_, snip) return snip.captures[1] .. "\\cot"    end) }),
  mar("([^\\\\])(csc)",    { f(function(_, snip) return snip.captures[1] .. "\\csc"    end) }),

  -- ── Linear algebra ───────────────────────────────────────────────────────────
  ma("ref",  { t("\\xRightarrow{\\text{REF}}") }),
  ma("rref", { t("\\xRightarrow{\\text{RREF}}") }),

  -- ── Probability ──────────────────────────────────────────────────────────────
  ma("cov",    { t("\\operatorname{Cov}("), i(1), t(")"), i(2) }),
  ma("iid",    { t("\\overset{\\text{iid}}{\\sim}") }),
  ma("follows",{ t("\\sim") }),

  -- ── Quantum ──────────────────────────────────────────────────────────────────
  ma("bra",   { t("\\bra{"), i(1), t("} "), i(2) }),
  ma("ket",   { t("\\ket{"), i(1), t("} "), i(2) }),
  ma("brk",   { t("\\braket{ "), i(1), t(" | "), i(2), t(" } "), i(3) }),
}

return snips, autosnips
