#!/usr/bin/env bash
# SessionStart hook：把强制指令注入上下文
# skill 名与 description 已在 skill 列表里常驻，这里只补「必须加载」这条硬要求
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<EXTREMELY_IMPORTANT>\n带 liasica-skills: 前缀的 skill 是硬性规范，不是参考资料。任务命中某个 skill 的 description 所述场景时，必须先用 Skill 工具加载它再动手，有一分可能相关就加载。凭记忆作答等同于违规。\n</EXTREMELY_IMPORTANT>"}}
EOF
