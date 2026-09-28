# Installing the Our World in Data skill

Find your app here:

| Your app | How you install it |
|---|---|
| [Claude app](#claude-app-web-and-desktop) | in the app, in a few clicks |
| [ChatGPT app](#chatgpt-app) | in the app, in a few clicks |
| [Claude Code](#claude-code) | two commands, at Claude Code's own prompt |
| [Codex](#codex) | two commands, in a terminal |
| [Anything else](#other-agents-gemini-cli-cursor-copilot-) | one command in a terminal |

They all install the same thing, none of them needs an Our World in Data account,
and nothing on our side costs anything. Two more ways are further down this page:
[uploading the skill yourself](#claude-app-by-uploading-the-skill) and
[copying the folder](#manual).

## Claude app (web and desktop)

**You need a paid Claude plan** — Pro, Max, Team or Enterprise. Plugins and skills
are both paid features, so on the free plan there is no way to add this to the
Claude app.

You are going to point Claude at this project on GitHub, where the skill lives. It
arrives as a **plugin** — the wrapper a skill comes in. Install the plugin and you
have the skill. Claude calls its list of add-ons a *marketplace*; you don't need to
know more than that, because you paste one short address and Claude does the rest.
You don't need a GitHub account.

1. Open Claude. Click your name at the bottom left, then **Customize**, then the
   **Plugins** tab.
2. Under *Personal plugins*, click the **+** at the right-hand end of the heading,
   then **Add marketplace**, then **Add from a repository**.
3. A box appears. Type `owid/skills` — with the slash, and no `https://` — then
   press Enter, or click the button beside the box.
4. Click **Browse plugins**, find **Our World in Data**, and click **Install**.
5. Look for a switch next to its name and make sure it is on. If there is no
   switch, it is already on.
6. Start a **new** chat. The plugin only applies to conversations you begin after
   installing it.

Menu names change from time to time. If you can't find **Customize**, look for
**Settings**, then anything called **Plugins**, **Extensions** or **Add-ons**.

Then [check it worked](#check-it-worked).

## Claude app, by uploading the skill

This needs a paid Claude plan too, so it is not a way around that. Use it when you
want a fixed copy — a particular version, or a branch you are trying out.

1. Turn on **Settings → Capabilities → Code execution and file creation**. Skills
   are greyed out without it.
2. Go to <https://github.com/owid/skills>, click the green **Code** button, then
   **Download ZIP**. Unzip it and open the `skills` folder inside. Compress the
   `owid` folder on its own — right-click it, then **Compress** on a Mac or
   **Send to → Compressed folder** on Windows. `owid` has to be the top level of
   the zip. (In a terminal: `cd skills && zip -r owid.zip owid`.)
3. In Claude, go to **Customize → Skills → + → Create skill → Upload a skill**
   and choose that zip.

An uploaded skill never updates itself, so repeat this when you want a newer
version.

## ChatGPT app

The skill isn't in OpenAI's own plugin list yet, so you point ChatGPT at where it
lives on GitHub. This works on chatgpt.com as well as in the desktop app.

1. Click your name at the bottom left, then **Settings**, then **Plugins**. Choose
   to add — or import — a marketplace, and give `owid/skills` as the source. That
   is the address of this project on GitHub. You may see other boxes; leave them
   empty. You don't need a GitHub account.
2. Find **Our World in Data** in the list and install it. If there is a switch next
   to its name, make sure it is on.
3. Start a **new** conversation. The plugin only applies to chats you start after
   installing it.

If the menu names don't match what you see, look for anything called **Plugins**,
**Extensions** or **Add-ons**.

Then [check it worked](#check-it-worked).

## Claude Code

Type these two lines into Claude Code's own prompt, one at a time. They start
with a slash, which is how it knows they are commands rather than questions.

```
/plugin marketplace add owid/skills
/plugin install owid@owid-skills
```

The first line tells Claude Code where to find the skill; the second installs it.
Claude Code usually reloads for you; if it tells you to run `/reload-plugins`, run
it. Then [check it worked](#check-it-worked).

## Codex

Codex is a tool you run by typing in a terminal. If that isn't you, use one of the
app routes above.

This repo is also an [Agent Plugins](https://agent-plugins.org) package, the
format ChatGPT and Codex share. In a terminal:

```bash
codex plugin marketplace add owid/skills
codex plugin add owid@owid-skills
```

The first line registers this project as a source; the second installs the skill.
`codex plugin list` shows what your marketplaces offer, with this one among them.
Then [check it worked](#check-it-worked).

## Other agents (Gemini CLI, Cursor, Copilot, …)

This is a standard [Agent Skill](https://agentskills.io), read as-is by Codex,
Gemini CLI, Cursor, GitHub Copilot and many other tools — nothing Claude-specific
is needed. The [`skills`](https://github.com/vercel-labs/skills) CLI finds the
agents you have installed and asks which of them to install into. It supports 75
and more.

```bash
npx skills add owid/skills            # into the current project
npx skills add owid/skills --global   # user-level, across all your projects
```

Add `--agent '*'` to install to every supported agent, or `--list` to preview first.

## Manual

This one is for developers. If you are not comfortable in a terminal, use one of
the app routes above.

The skill is a plain [Agent Skills](https://agentskills.io) folder, so you can also copy or symlink it into whatever directory your agent reads. Clone the repo:

```bash
git clone https://github.com/owid/skills owid-skills
```

Then put `owid-skills/skills/owid` where your agent looks for skills:

- **Per project** — `./.agents/skills/` (the shared convention read by Codex, Cursor, OpenCode, …)
- **Per user** — your agent's own skills directory, e.g. `~/.codex/skills/`, `~/.gemini/skills/`, or `~/.claude/skills/`

Copy the whole `owid/` directory, not just `SKILL.md`: the references live next to it.

## Check it worked

Start a new chat and ask:

> Use the Our World in Data skill to fetch the data behind this chart:
> https://ourworldindata.org/grapher/child-mortality — the complete time series
> for Uganda, and the source the chart relies on.

A working install comes back with the whole series for Uganda — about seventy
yearly figures, starting in the 1950s — and names **Gapminder and the UN
Inter-agency Group for Child Mortality Estimation** as the source, rather than
"Our World in Data".

If that is what you got, you are done — there is nothing else to set up.

Naming the skill in the question is deliberate: an assistant that doesn't have it
will tell you so. One that has it but didn't fetch anything will summarise or
invent the numbers instead of returning the series. If either happens, see
[Not working?](#not-working) below.

## Not working?

If you installed in the Claude or ChatGPT app, check three things first: the
plugin is switched on, you started a new chat after switching it on, and your
question is specific enough — "find the OWID chart on child mortality and pull
the data" will use it, "what's OWID" may not. If it still doesn't use the skill, ask for it
by name: *use the Our World in Data skill to…*

For anything else, see the [FAQ](FAQ.md#my-agent-isnt-using-the-skill-at-all).

## Keeping the skill up to date

However you installed it, you got the skill as it was that day. Nothing here
refreshes itself until you say so. Find the way you installed it:

- **Claude app.** Anthropic doesn't document whether Claude refreshes a
  marketplace you added yourself, and we have not been able to confirm it. If the
  skill looks out of date, remove the marketplace in **Customize → Plugins** and
  add it again.

- **Claude Code plugin.** Auto-update is off by default for marketplaces other than Anthropic's own. Turn it on once: run `/plugin`, open the **Marketplaces** tab, select `owid-skills` and choose **Enable auto-update**. Claude Code then checks within about ten minutes of a session starting, and tells you to `/reload-plugins` when something changed. To update by hand instead:

  ```bash
  claude plugin marketplace update owid-skills   # refresh the catalog
  claude plugin update owid@owid-skills          # then restart, or /reload-plugins
  ```

  Refreshing the marketplace on its own does not update the installed plugin; the second command does.

- **ChatGPT app.** Remove **Our World in Data** from your plugins list and install
  it again from the same marketplace.

- **Codex.** Refresh the source, then reinstall, then start a new Codex session:

  ```bash
  codex plugin marketplace upgrade owid-skills   # refresh the source
  codex plugin remove owid@owid-skills           # then reinstall
  codex plugin add owid@owid-skills
  ```

  A Codex install is Codex's own; the ChatGPT app keeps its plugins separately.

- **`skills` CLI.** `npx skills add` installs one copy per scope, symlinks each agent's directory to it by default, and records what it installed — `skills-lock.json` in the project, `~/.agents/.skill-lock.json` for a global install. Update everything in that scope with:

  ```bash
  npx skills update            # -g for the user-level install, -p for the project one
  ```

- **Uploaded skill.** A fixed copy. Download and upload it again.

- **Manual.** A copied directory is frozen; copy it again to update. A symlink into your clone follows the clone, so `git pull` in `owid-skills` is enough.

There are no version numbers to keep track of. We change the skill in place, and
each of these steps picks up the newest version.

