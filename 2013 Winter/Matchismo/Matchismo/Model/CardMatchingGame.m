//
//  CardMatchingGame.m
//  Matchismo
//
//  Created by Hugo Ferreira on 2013/08/02.
//  Copyright (c) 2013 Mindclick. All rights reserved.
//

#import "CardMatchingGame.h"

@interface CardMatchingGame()

@property (readwrite, nonatomic) int score;
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic) NSMutableArray *cards;

@end

@implementation CardMatchingGame
{}
#pragma mark - Initializers

- (id)initWithCardCount:(NSUInteger)count fromDeck:(Deck *)deck matchCards:(NSUInteger)numCards
{
    self = [super init];
    if (self) {
        for (int i = 0; i < count; i++) {
            Card *card = [deck drawRandomCard];
            if (!card) {
                self = nil;
            } else {
                self.cards[i] = card;
            }
        }
        self.numCardsToMatch = numCards;
    }
    return self;
}

- (id)initWithCardCount:(NSUInteger)count fromDeck:(Deck *)deck
{
    return [self initWithCardCount:count fromDeck:deck matchCards:2];
}

#pragma mark -

- (NSMutableArray *)cards
{
    if (!_cards) _cards = [[NSMutableArray alloc] init];
    return _cards;
}

#define SCORE_FLIP_COST         -1
#define SCORE_MISMATCH_PENALTY  -2
#define SCORE_MATCH_BONUS       4

/**
 The "brain" of the game.
 
 This is where the actual game rules are defined.
 Sets the `lastMessage` property to describe what has been going on in the game.
 */
- (void)flipCardAtIndex:(NSUInteger)index
{
    NSString *msg;
    int roundScore = 0;
    Card *card = [self cardAtIndex:index];
    
    BOOL(^isCardInPlay)(id, NSUInteger, BOOL*) = ^(id obj, NSUInteger idx, BOOL *stop) {
        return (BOOL)(![(Card *)obj isUnplayable] && [(Card *)obj isFaceUp]);
    };
    
    if (!card.isUnplayable) {
        if (!card.isFaceUp) {
            // Play the game
            NSArray *cardsInPlay = [self.cards objectsAtIndexes:[self.cards indexesOfObjectsPassingTest:isCardInPlay]];
            NSString *otherCardNames = [cardsInPlay componentsJoinedByString:@" "];
            
            // Check for a match if enough cards are flipped
            if (cardsInPlay.count == self.numCardsToMatch - 1) {
                int cardScore = [card match:cardsInPlay];
                if (cardScore > 0) {
                    // Cards match
                    card.unplayable = YES;
                    [cardsInPlay enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        [obj setUnplayable:YES];
                    }];
                    roundScore += cardScore * SCORE_MATCH_BONUS * (self.numCardsToMatch - 1);
                    msg = [NSString stringWithFormat:@"Matched %@ with %@ (%+d)", card, otherCardNames, roundScore];
                } else {
                    // Cards don't match
                    [cardsInPlay enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        [obj setFaceup:NO];
                    }];
                    if (cardScore < 0) {
                        roundScore += SCORE_MISMATCH_PENALTY * -cardScore;
                    } else {
                        roundScore += SCORE_MISMATCH_PENALTY * (self.numCardsToMatch - 1);
                    }
                    msg = [NSString stringWithFormat:@"%@ with %@ don't match (%+d)", card, otherCardNames, roundScore];
                }
            }
            // Score penalty for flipping a card
            roundScore += SCORE_FLIP_COST;
            if (!msg) {
                msg = [NSString stringWithFormat:@"Flipped up %@", card];
            }
        }
        // Flip it!
        card.faceup = !card.faceup;
        self.score += roundScore;
        if (msg) {
            [self.messages addObject:msg];
        }
    }
}

- (Card *)cardAtIndex:(NSUInteger)index
{
    return (index < self.cards.count)? self.cards[index] : nil;
}

- (NSMutableArray *)messages
{
    if (!_messages) _messages = [[NSMutableArray alloc] init];
    return _messages;
}

- (NSString *)lastMessage
{
    return [self.messages lastObject];
}

- (NSArray *)lastMessages
{
    return [self.messages copy];
}

@end
