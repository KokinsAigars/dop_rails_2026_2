

search logic

1. The Trigger (User Input)
   Action: User types "rukk" into the text field.

    Stimulus: search-input#submit waits 300ms (debounce) then calls this.element.requestSubmit().

    Turbo: Captures the form submission and sends an AJAX request to /dic/search_indexes?q=rukk with the header Accept: text/vnd.turbo-stream.html.


2. The Brain (Rails Controller)
   Normalization: The query is cleaned (e.g., rukk stays rukk).

    SQL Logic: Postgres performs the search using the GIN trigram index.

    Ranking: The CASE WHEN block assigns a search_rank:

     0: Exact Match (rukkho)

     1: Normalized Match

     2: Prefix Match (rukkha...)

     3: Fuzzy/Contains Match (akkha-rukkha)

    Pagination: Kaminari slices the results (e.g., first 50) and calculates the global-index offset.


3. The Delivery (Turbo Frame)
   Response: Rails sends back a <turbo-frame id="search_index_results"> containing a <ul> with the search-result Stimulus controller attached.

    DOM Swap: Turbo sees the matching ID and swaps the old list with the new 50 items.

    Data Leak: Each <li> carries its "intelligence" in data attributes:

     data-score: The search_rank (0–3).

     data-term: The string for alphabetical sorting.

     data-global-index: The absolute position in the 90,000-word set.


5. The Manipulation (DOM Refinement)
   Deduplication: The controller loops through the sorted array. If it sees the same data-term twice, it hides the second one and adds a ++ badge to the first one.

    The Reveal: The controller clears the <ul> and appends the items back in their new, perfect order.

    The Divider: If the logic detects a jump from score 2 to score 3, it injects a <hr> Also matches... separator.


6. The Landing (User Click)
   Interaction: User clicks rukkho ++.

    Breakout: Because of data-turbo-frame="_top", Turbo performs a full-page visit to the Entry page.

    Result: The user lands on a page where your "Homograph Hub" logic is and shows them all definitions for that term.



The secret to this system is that Postgres decides who makes the "Top 50" list, but Stimulus decides how those 50 are arranged on the shelf.





Stimulus Controller

The "Deduplication" Logic Flow
    The Registry (seenCount): You create a temporary dictionary in memory.
    The Sweep: You iterate through your already-sorted items.
    The Verdict:
        First time seeing "rukkho": It stays visible.
        Second time seeing "rukkho": You set display: none. It’s still in the DOM (so links work if needed), but the user doesn't see a duplicate.
        The Badge: You look back at the "Original" (the one you kept visible) and append the ++

    How it works step-by-step:
        Initialization: seenCount starts empty.
        First "rukkho": * seenCount["rukkho"] becomes 1.
        The if (seenCount[term] > 1) is false, so it stays visible.
        Second "rukkho": * seenCount["rukkho"] becomes 2.
        The if is now true.
        Stimulus hides the second "rukkho" and goes back to the first one to add the ++ badge.

The Step-by-Step Logic Flow
Imagine the loop has just reached the second "rukkho" in your list.

1. The Setup
   TypeScript
   const term = item.dataset.term || ""
   Action: The computer looks at the current <li> and pulls the word "rukkho" from the data attribute.

2. The Tally (The "Seen" List)
   TypeScript
   seenCount[term] = (seenCount[term] || 0) + 1
   Action: It looks at your seenCount object. Since it already saw "rukkho" once before, the count moves from 1 to 2.

3. The "Duplicate" Decision
   TypeScript
   if (seenCount[term] > 1) {
   item.classList.add("is-homograph")
   item.style.display = "none"
   }
   Action: Because the count is 2, it triggers this block.

Result: This specific <li> is hidden from the user's eyes, but it still exists in the background.

4. Finding the "Master" (The find logic)
   TypeScript
   const original = items.find(i => i.dataset.term === term && i.style.display !== "none")
   The Logic: This is the computer saying: "Okay, I just hid a duplicate. Now I need to find the version of 'rukkho' that I actually kept visible so I can put a badge on it."

How it searches: it looks through the entire array of 100 items again, looking for an item that has the name "rukkho" AND is not hidden (display !== "none").

5. The Badge (The ++)
   TypeScript
   if (original && !original.querySelector('.homograph-indicator')) {
   // ... create badge ...
   original.appendChild(badge)
   }
   Action: Once it finds that "Master" (the first "rukkho"), it checks: "Does this already have a badge?"

Result: If not, it glues the ++ badge onto that first item.
---------------------------






1. The "Seating Chart" (parseInt & dataset)
   a and b are two <li> elements that the sort function is currently comparing.

a.dataset.score: This is Stimulus reaching into the DOM to grab the number you calculated in the Rails Controller (search_rank).

parseInt(...): Since HTML attributes are always strings (e.g., "0"), we turn them into actual numbers so the computer can do math.

|| "0": This is your safety net. If a row somehow misses a score, we treat it as a 0 so it doesn't crash the dance.

2. Phase One: The Rank Battle (The "VIP" Section)
   TypeScript
   if (scoreA !== scoreB) {
   return scoreA - scoreB
   }
   The computer asks: "Are these two words in the same 'league' of relevance?"

If scoreA is 0 (Exact match) and scoreB is 3 (Fuzzy match):

0 - 3 = -3.

In sorting logic, a negative result means "A comes first."

The Result: All your Exact matches (0) and Prefixes (1, 2) instantly teleport to the top of the list, regardless of their spelling.

3. Phase Two: The Alphabetical Waltz (The Tie-Breaker)
   TypeScript
   const termA = a.dataset.term || ""
   const termB = b.dataset.term || ""
   return termA.localeCompare(termB, 'pi')
   If the computer sees two words with the same score (e.g., two different fuzzy matches that both have a score of 3), it moves to the second dance.

It looks at the actual Pāḷi text.

localeCompare(..., 'pi'): This is the "Pāḷi Waltz." It knows that in your dictionary, characters like ā or ñ have specific spots in the alphabet that a standard English sort would get wrong.

4. The Final DOM Re-ordering
   After the dance is finished, the array is sorted in memory, but the screen hasn't changed yet.

TypeScript
items.forEach(item => this.element.appendChild(item))
This is the final move. You tell the browser: "Okay, follow this new order and move the actual HTML elements into their new seats." Because appendChild moves elements rather than copying them, it’s fast and keeps all your event listeners (like the links) intact.

Summary of the Flow
Rails Controller: Assigns a "Quality Score" (0–3).

HTML: Carries that score as data-score.

Stimulus (The Judge): Uses parseInt to compare scores.

Stimulus (The Librarian): Uses localeCompare to break ties alphabetically.

Browser (The Stage): Re-arranges the list.





Stage,Spell Cast,Result
Rails SQL,CASE WHEN... END AS search_rank,Scores every word from 0 (Perfect) to 3 (Fuzzy).
Stimulus Sort,scoreA - scoreB,"Gravity pulls the ""heavy"" (relevant) words to the top."
Stimulus Sort (Tie-break),localeCompare('pi'),The remaining words line up in perfect Pāḷi order.
Deduplication,seenCount[term] > 1,"The ""clones"" are hidden and the original gets a ++ badge."



ince you are using parseInt(a.dataset.score || "0"), if you ever want to add a new layer of relevance (like boosting words from a specific author or a "Favorite" list), you just change the number in the Rails Controller. The Stimulus "dance" will automatically handle the new numbers without you changing a single line of JavaScript.















































