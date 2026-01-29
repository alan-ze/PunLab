import random
import sys
import os

MASTER_STREAK = 3  # correct answers needed to master a card

class Flashcard:
    def __init__(self, term, definition):
        self.term = term.strip()
        self.definition = definition.strip()
        self.correct_streak = 0
        self.mastered = False

def load_flashcards(filepath):
    if not os.path.exists(filepath):
        print("File not found.")
        sys.exit(1)

    cards = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            if not line.strip():
                continue
            for sep in ["|", " - ", ":", "\t"]:
                if sep in line:
                    term, definition = line.split(sep, 1)
                    cards.append(Flashcard(term, definition))
                    break
    return cards

def multiple_choice(card, cards):
    choices = [card.definition]
    others = [c.definition for c in cards if c != card]
    choices.extend(random.sample(others, min(3, len(others))))
    random.shuffle(choices)

    print(f"\nTERM: {card.term}")
    for i, choice in enumerate(choices):
        print(f"{i + 1}. {choice}")

    try:
        answer = int(input("Choose the correct definition: "))
        return choices[answer - 1] == card.definition
    except:
        return False

def written(card):
    print(f"\nTERM: {card.term}")
    answer = input("Type the definition: ").strip().lower()
    return answer in card.definition.lower() or card.definition.lower() in answer

def learn_session(cards):
    print("\n📘 Quizlet Learn Mode Started")
    print("Type Ctrl+C to exit\n")

    while not all(card.mastered for card in cards):
        active_cards = [c for c in cards if not c.mastered]
        card = random.choice(active_cards)

        # Choose question type based on performance
        if card.correct_streak < 2:
            correct = multiple_choice(card, cards)
        else:
            correct = written(card)

        if correct:
            print("✅ Correct!")
            card.correct_streak += 1
            if card.correct_streak >= MASTER_STREAK:
                card.mastered = True
                print("🎉 Card mastered!")
        else:
            print(f"❌ Incorrect.\nCorrect answer:\n{card.definition}")
            card.correct_streak = max(0, card.correct_streak - 1)

        mastered_count = sum(c.mastered for c in cards)
        print(f"\nProgress: {mastered_count}/{len(cards)} mastered")

    print("\n🏆 All cards mastered! Learn session complete.")

def main():
    if len(sys.argv) != 2:
        print("Usage: python learn.py flashcards.txt")
        sys.exit(1)

    filepath = sys.argv[1]
    cards = load_flashcards(filepath)

    if len(cards) < 2:
        print("Need at least 2 flashcards.")
        sys.exit(1)

    learn_session(cards)

if __name__ == "__main__":
    main()