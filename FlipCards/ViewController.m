//
//  ViewController.m
//  FlipCard
//
//  Created by roy gal on 10/26/16.
//  Copyright © 2016 roy gal. All rights reserved.
//

#import "ViewController.h"

#import "CardMatchingGame.h"

#import "playingCard.h"

#import "Grid.h"


@interface ViewController ()

@property(strong,nonatomic) Deck *deck;

@property(strong, nonatomic) CardMatchingGame *game;

@property(weak, nonatomic) IBOutlet UILabel *scoreLable;

@property (weak, nonatomic) IBOutlet UIView *gridView;

@property(strong, nonatomic) NSMutableArray *cardViews;

@property(strong, nonatomic) Grid *grid;

@property (weak, nonatomic) IBOutlet UIButton *addCardsButton;

@end


@implementation ViewController


-(NSMutableArray *)cardViews
{
    if (!_cardViews)
    {
        _cardViews = [NSMutableArray arrayWithCapacity:self.numberOfStartingCards];
    }
    
    return _cardViews;
}


-(CardMatchingGame*)game
{
    if (!_game)
    {
        _game = [[CardMatchingGame alloc] initWithCardCount:self.numberOfStartingCards usingDeck:[self createDeck]];
    }
    
    return _game;
}



// Abstract
-(Deck *)createDeck
{
    //return [[PlayingCardDeck alloc] init];
    
    return nil;
}



#define CARDSPACINGINPERCENT 0.08
- (void)updateUI
{
    for (NSUInteger cardIndex = 0;
         cardIndex < self.game.numberOfDealtCards;
         cardIndex++) {
        Card *card = [self.game cardAtIndex:cardIndex];
        
        NSUInteger viewIndex = [self.cardViews indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[UIView class]]) {
                if (((UIView *)obj).tag == cardIndex) return YES;
            }
            return NO;
        }];
        UIView *cardView;
        if (viewIndex == NSNotFound) {
            if (!card.matched) {
                cardView = [self createViewForCard:card];
                cardView.tag = cardIndex;
                cardView.frame = CGRectMake(self.gridView.bounds.size.width,
                                            self.gridView.bounds.size.height,
                                            self.grid.cellSize.width,
                                            self.grid.cellSize.height);
                
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(touchCard:)];
                [cardView addGestureRecognizer:tap];
                
                [self.cardViews addObject:cardView];
                viewIndex = [self.cardViews indexOfObject:cardView];
                [self.gridView addSubview:cardView];
            }
        } else {
            cardView = self.cardViews[viewIndex];
            if (!card.matched) {
                [self updateView:cardView forCard:card];
            } else {
                if (self.removeMatchingCards) {
                    [self.cardViews removeObject:cardView];
                    [UIView animateWithDuration:1.0
                                     animations:^{
                                         cardView.frame = CGRectMake(0.0,
                                                                     self.gridView.bounds.size.height,
                                                                     self.grid.cellSize.width,
                                                                     self.grid.cellSize.height);
                                         
                                     } completion:^(BOOL finished) {
                                         [cardView removeFromSuperview];
                                     }];
                } else {
                    cardView.alpha = card.matched ? 0.6 : 1.0;
                }
            }
        }
    }
    
    self.grid.minimumNumberOfCells = [self.cardViews count];
    
    NSUInteger changedViews = 0;
    for (NSUInteger viewIndex = 0; viewIndex < [self.cardViews count]; viewIndex++) {
        CGRect frame = [self.grid frameOfCellAtRow:viewIndex / self.grid.columnCount
                                          inColumn:viewIndex % self.grid.columnCount];
        frame = CGRectInset(frame, frame.size.width * CARDSPACINGINPERCENT, frame.size.height * CARDSPACINGINPERCENT);
        UIView *cardView = (UIView *)self.cardViews[viewIndex];
        if (![self frame:frame equalToFrame:cardView.frame]) {
            [UIView animateWithDuration:0.5
                                  delay:1.5 * changedViews++ / [self.cardViews count]
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 cardView.frame = frame;
                             } completion:NULL];
        }
    }
    
    self.scoreLable.text = [NSString stringWithFormat:@"Score: %ld", (long)self.game.score];
}


#define FRAMEROUNDINGERROR 0.01

- (BOOL)frame:(CGRect)frame1 equalToFrame:(CGRect)frame2
{
    if (fabs(frame1.size.width - frame2.size.width) > FRAMEROUNDINGERROR) return NO;
    if (fabs(frame1.size.height - frame2.size.height) > FRAMEROUNDINGERROR) return NO;
    if (fabs(frame1.origin.x - frame2.origin.x) > FRAMEROUNDINGERROR) return NO;
    if (fabs(frame1.origin.y - frame2.origin.y) > FRAMEROUNDINGERROR) return NO;
    return YES;
}



- (UIView *)createViewForCard:(Card *)card
{
    UIView *view = [[UIView alloc] init];
    [self updateView:view forCard:card];
    return view;
}

- (void)updateView:(UIView *)view forCard:(Card *)card
{
    view.backgroundColor = [UIColor redColor];
}

- (void)touchCard:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        Card *card = [self.game cardAtIndex:gesture.view.tag];
        if (!card.matched) {
            [UIView transitionWithView:gesture.view
                              duration:0.5
                               options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                                   card.chosen = !card.chosen;
                                   [self updateView:gesture.view forCard:card];
                               } completion:^(BOOL finished) {
                                   card.chosen = !card.chosen;
                                   [self.game chooseCardAtIndex:gesture.view.tag];
                                   [self updateUI];
                               }];
        }
    }
}


- (IBAction)dealButton:(id)sender
{
    
    UIAlertView *newGameAlert = [[UIAlertView alloc] initWithTitle:@"Press START to begin a new game"
                                                           message:nil
                                                          delegate:nil
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:@"START",nil];
    [newGameAlert show];
    
    
    self.game = nil;
   
    for (UIView *subView in self.cardViews)
    {
        [UIView animateWithDuration:0.5
                         animations:^{
                             subView.frame = CGRectMake(0.0,
                                                        self.gridView.bounds.size.height,
                                                        self.grid.cellSize.width,
                                                        self.grid.cellSize.height);
                         }
                         completion:^(BOOL finished)
         {
                             [subView removeFromSuperview];
                         }];
    }
    self.cardViews = nil;
    self.grid = nil;
    self.addCardsButton.enabled = YES;
    self.addCardsButton.alpha = 1.0;
    [self updateUI];}


- (Grid *)grid
{
    if (!_grid) {
        _grid = [[Grid alloc] init];
        _grid.cellAspectRatio = self.maxCardSize.width / self.maxCardSize.height;
        _grid.minimumNumberOfCells = self.numberOfStartingCards;
        _grid.maxCellWidth = self.maxCardSize.width;
        _grid.maxCellHeight = self.maxCardSize.height;
        _grid.size = self.gridView.frame.size;
    }
    return _grid;
}


- (IBAction)touchAddCardsButton:(UIButton *)sender
{
    for (int i = 0; i < sender.tag; i++)
    {
        [self.game drawNewCard];
    }
    if (self.game.deckIsEmpty)
    {
        sender.enabled = NO;
        sender.alpha = 0.5;
        
        UIAlertView *newGameAlert = [[UIAlertView alloc] initWithTitle:@"Deck is Empty!"
                                                               message:nil
                                                              delegate:nil
                                                     cancelButtonTitle:nil
                                                     otherButtonTitles:@"START",nil];
        [newGameAlert show];

    }
    [self updateUI];
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.grid.size = self.gridView.bounds.size;
    [self updateUI];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
}




@end
