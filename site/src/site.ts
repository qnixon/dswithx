export const SITE_NAME = 'DS with X';

// Until launch, ask search engines not to index the site. Set to true at launch.
export const LAUNCHED = true;

// Languages listed first, in this order, everywhere languages appear (tabs,
// coverage grid, language index); the rest follow alphabetically.
export const LANGUAGES_FIRST = ['python'];

// Concept pages group the language tabs into these labeled rows, in this
// order. A language missing from every group appears in a final "Other" row.
export const LANGUAGE_GROUPS: { label: string; languages: string[] }[] = [
  { label: 'Scripting', languages: ['python', 'javascript', 'ruby', 'lua', 'awk', 'tcl'] },
  { label: 'Arrays and math', languages: ['r', 'julia', 'octave', 'apl', 'fortran'] },
  { label: 'Systems', languages: ['c', 'cpp', 'go', 'rust', 'swift'] },
  { label: 'Functional and logic', languages: ['haskell', 'ocaml', 'common-lisp', 'prolog'] },
  { label: 'Teaching', languages: ['basic', 'pascal'] },
  { label: 'Business and databases', languages: ['java', 'cobol', 'postgresql'] },
];

// The home page names every language until there are more than this many;
// after that it gives a count and names the HOME_HIGHLIGHTS that exist.
export const HOME_LIST_LIMIT = 8;
export const HOME_HIGHLIGHTS = ['python', 'r', 'cobol'];

export const REPO_URL = 'https://github.com/qnixon/dswithx';
export const BRANCH = 'main';

export const githubUrl = (repoPath: string) => `${REPO_URL}/blob/${BRANCH}/${repoPath}`;
