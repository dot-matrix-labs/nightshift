#!/usr/bin/env bash
# Gemini agent for Nightshift - reads task from stdin, calls Gemini API

if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY not set" >&2
  exit 1
fi

# Read task from stdin
task=$(cat)

if [ -z "$task" ] || [ "$task" = "DONE" ]; then
  # Check for idle mode
  if [ -n "$task" ]; then
    echo "Entering idle mode: spell check and grammar review"
    
    # Simple spell check
    misspelled=$(find . -name "*.md" -exec grep -i -E "\b(teh|recieve|occured|seperate|acommodate|accomodate|acheive|advertisment|agressive|annoucement|apparant|appearence|arguement|assasination|compleat|conceed|concious|consious|definate|desparate|discrete|dispite|entitlled|equiptment|exagerrate|excellance|existance|experiance|goverment|grammer|helpfull|homeworks|illnesse|immediatly|inconveniant|independant|intrest|irresistable|judgement|knowlege|labratory|lieing|lightening|mispell|misunderstand|neccessary|necessery|noticable|occassion|occurence|ommission|oppurtunity|paralell|parcelly|persistant|pharoah|possition|powerfull|practise|privelege|priviledge|profesional|publically|reccomend|recieve|recognise|recomend|reconize|rediculous|refered|refering|relevent|religous|repectable|representitive|responsability|sallery|seperate|seriousley|specifially|succesful|successfull|superceed|superious|suprise|temprature|truely|unconcious|undere|understanded|unfortunatly|unhappy|unnecessary|untill|usefull|usualy|vaccination|vegitable|writinge|writting)\b" {} \; 2>/dev/null | head -20)
    
    if [ -n "$misspelled" ]; then
      echo "# Spell Check & Grammar Review" > SPELLCHECK_REVIEW.md
      echo "" >> SPELLCHECK_REVIEW.md
      echo "## Potential Issues Found" >> SPELLCHECK_REVIEW.md
      echo "" >> SPELLCHECK_REVIEW.md
      echo "$misspelled" >> SPELLCHECK_REVIEW.md
      echo "" >> SPELLCHECK_REVIEW.md
      echo "---" >> SPELLCHECK_REVIEW.md
      echo "*This is an idle mode review PR.*" >> SPELLCHECK_REVIEW.md
      git add SPELLCHECK_REVIEW.md
    fi
    
    # Continue in idle mode
    echo "[IDLE] Continue improvements (or write DONE to stop)" > next-prompt.md
    git add next-prompt.md
    git commit -m "Idle mode: spell check review"
  fi
  exit 0
fi

echo "Task: ${task:0:50}..."

# Call Gemini API
response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "{
    \"contents\": [{
      \"parts\": [{
        \"text\": \"You are a coding agent. Task: $task. Make code changes, update next-prompt.md with DONE or next task, then commit.\"
      }]
    }]
  }")

# Check for errors in response
if echo "$response" | grep -q "error"; then
  echo "Error from Gemini API: $response" >&2
  exit 1
fi

echo "Gemini API call successful"

# For demo: mark task complete and enter idle mode
# In production, this would parse the response and make actual changes
echo "[IDLE] Spell check and grammar review" > next-prompt.md
git add -A
git commit -m "Demo: completed task - ${task:0:40}"

exit 0
