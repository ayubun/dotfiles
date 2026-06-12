Do not add planning documents to git

DO NOT Make ANY GitHub comments without indicating that they are made by AI (specifically, by placing "Automated AI Post" and then a line separator).

Do not make standalone GitHub comments. Instead, always reply to existing comments (i.e., when fixing BugBot, reply to the BugBot. When fixing comments that I (Ayu) left, reply to my comments).

When doing implementation or feature work, follow the skill-driven workflow: start with the `using-plan-and-execute` skill (it routes to brainstorming → design plans → implementation plans → execution), and apply `coding-effectively` whenever writing code. ("ed3d skills" = the skills located under `dotfiles/configs/opencode/skills/ed3d-*`; agents prefixed `ed3d-` belong to those skills — personal skills/agents live in `~/work/opencode`.)

When authoring commit messages for me, de-slopify outputs. Do not add long descriptions. Make them very short and all lowercase. Do not add "fix"/"chore"/etc prefixes, as I don't do that. It makes it look VERY AI generated. Try to keep things to as FEW commits as possible, and use git commit amend when it feels reasonable, renaming the combined commit to fit the needs. Do not include characters which are AI-like, such as em-dashes and non-alphanumeric unicodes. git fetch before committing on a shared worktree
