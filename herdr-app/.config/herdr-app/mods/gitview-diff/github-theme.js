// GitHub palettes from Guided Review's theme.ts and github-*-default syntax
// themes. Keep gitview's tokenizer; translate its output colors by token role.
const LIGHT = {
  background: "#ffffff", foreground: "#1f2328", muted: "#59636e", surface: "#f6f8fa",
  addition: "#dafbe1", deletion: "#ffebe9",
  additionGutter: "#aceebb", deletionGutter: "#ffcecb",
  additionWord: "#aceebb", deletionWord: "#ffcecb",
  additionMarker: "#116329", deletionMarker: "#82071e",
  syntax: {
    plain: "#1f2328", comment: "#6e7781", keyword: "#cf222e",
    string: "#0a3069", function: "#8250df", constant: "#0550ae",
    variable: "#953800", type: "#953800", escape: "#0550ae",
  },
};

const DARK = {
  background: "#0d1117", foreground: "#e6edf3", muted: "#9198a1", surface: "#161b22",
  addition: "#033a16", deletion: "#67060c",
  // Guided Review flattens the translucent gutters over the canvas, not
  // over the red/green line background beneath a native child element.
  additionGutter: "#1a4a29", deletionGutter: "#6b2b2b",
  additionWord: "#1a4a29", deletionWord: "#6b2b2b",
  additionMarker: "#aff5b4", deletionMarker: "#ffdcd7",
  syntax: {
    plain: "#e6edf3", comment: "#8b949e", keyword: "#ff7b72",
    string: "#a5d6ff", function: "#d2a8ff", constant: "#79c0ff",
    variable: "#ffa657", type: "#ffa657", escape: "#79c0ff",
  },
};

// Both engine palettes are accepted so rows from the previous appearance
// remain readable while the engine reloads after a light/dark switch.
const TOKEN_ROLE = {
  "#dcdfe4": "plain", "#abb2bf": "plain", "#323232": "plain", "#333333": "plain",
  "#5c6370": "comment", "#7f848e": "comment", "#969896": "comment",
  "#c678dd": "keyword", "#a71d5d": "keyword",
  "#98c379": "string", "#183691": "string",
  "#61afef": "function", "#795da3": "function",
  "#d19a66": "constant", "#0086b3": "constant",
  "#e06c75": "variable", "#ed6a43": "variable",
  "#e5c07b": "type", "#b4b4b4": "plain",
  "#56b6c2": "escape", "#63a35c": "string",
};

export const githubTheme = (dark) => dark ? DARK : LIGHT;

export function githubColor(value, dark) {
  const p = githubTheme(dark);
  const roles = {
    red: p.deletionMarker, green: p.additionMarker,
    "@ins": p.addition, "@del": p.deletion,
    "@ins_emph": p.additionWord, "@del_emph": p.deletionWord,
    "@ins_gutter": p.additionGutter, "@del_gutter": p.deletionGutter,
    "@gutter": p.muted, "@fold": p.surface, "@fold_fg": p.muted,
  };
  if (Object.hasOwn(roles, value)) return roles[value];
  if (typeof value === "string" && value.startsWith("#")) {
    return p.syntax[TOKEN_ROLE[value.toLowerCase()] ?? "plain"];
  }
  return value;
}
