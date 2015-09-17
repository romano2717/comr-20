//
//  ScheduleTableViewCell.m
//  comress
//
//  Created by Diffy Romano on 8/9/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "ScheduleTableViewCell.h"

@implementation ScheduleTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)initCellWithResultSet:(NSDictionary *)dict
{
    NSDictionary *imageTemplate = [dict objectForKey:@"ImageTemplate"];
    NSArray *imagesArray = [dict objectForKey:@"Images"];
    
    NSDictionary *beforeImageForChecklistLastObject = nil;
    NSDictionary *afterImageForChecklistLastObject = nil;
    
    int currentChecklistId = [[imageTemplate valueForKey:@"CheckListId"] intValue];
    
    for (NSDictionary *imagesDict in imagesArray) {
        int ImageType = [[imagesDict valueForKey:@"ImageType"] intValue];
        int CheckListId = [[imagesDict valueForKey:@"CheckListId"] intValue];
        
        if(ImageType == 1 && CheckListId == currentChecklistId)
        {
            if(beforeImageForChecklistLastObject == nil)
                beforeImageForChecklistLastObject = imagesDict;
        }
        
        else if(ImageType == 2 && CheckListId == currentChecklistId)
        {
            if(afterImageForChecklistLastObject == nil)
                afterImageForChecklistLastObject = imagesDict;
        }
        
        //we already have a before and after images, exit the loop
        if(beforeImageForChecklistLastObject != nil && afterImageForChecklistLastObject != nil)
            break;
    }
    
    

    NSString *Title = [imageTemplate valueForKey:@"Title"];
    NSString *numOfBeforeImages = nil;
    NSString *numOfAfterImages = nil;
    
    if([[imageTemplate valueForKey:@"MinNoOfImage"] intValue] > 0)
        numOfBeforeImages = [NSString stringWithFormat:@"Before (%@/%@)",[imageTemplate valueForKey:@"beforeImagesPair"],[imageTemplate valueForKey:@"MinNoOfImage"]];
    else
        numOfBeforeImages = @"Before";
    
    if([[imageTemplate valueForKey:@"MinNoOfImage"] intValue] > 0)
        numOfAfterImages = [NSString stringWithFormat:@"After (%@/%@)",[imageTemplate valueForKey:@"afterImagesPair"],[imageTemplate valueForKey:@"MinNoOfImage"]];
    else
        numOfAfterImages = @"After";

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    NSString *imagePath = [beforeImageForChecklistLastObject valueForKey:@"ImageName"];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:imagePath];
    UIImage *beforeImage = [UIImage imageWithContentsOfFile:filePath];
    
    NSString *imagePath2 = [afterImageForChecklistLastObject valueForKey:@"ImageName"];
    NSString *filePath2 = [documentsPath stringByAppendingPathComponent:imagePath2];
    UIImage *afterImage = [UIImage imageWithContentsOfFile:filePath2];
    
    
    
    
    
    //set ui
    _titleLabel.text = Title;
    
    //default images
    [_beforeImageBtn setImage:[UIImage imageNamed:@"noImage2@2x.png"] forState:UIControlStateNormal];
    _beforeImageBtn.tag = 3;
    
    [_afterImageBtn  setImage:[UIImage imageNamed:@"noImage2@2x.png"] forState:UIControlStateNormal];
    _afterImageBtn.tag = 4;
    
    if(beforeImage != nil)
    {
        [_beforeImageBtn setImage:beforeImage forState:UIControlStateNormal];
        _beforeImageBtn.tag = 1;
    }
    
    if(afterImage != nil)
    {
        [_afterImageBtn setImage:afterImage forState:UIControlStateNormal];
        _afterImageBtn.tag = 2;
    }
    
    
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:numOfBeforeImages];
    [attributeString addAttribute:NSUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:1]
                            range:(NSRange){0,[attributeString length]}];
    _beforeLabel.attributedText = [attributeString copy];
    
    
    NSMutableAttributedString *attributeString2 = [[NSMutableAttributedString alloc] initWithString:numOfAfterImages];
    [attributeString2 addAttribute:NSUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:1]
                            range:(NSRange){0,[attributeString2 length]}];
    _afterLabel.attributedText = [attributeString2 copy];
}



@end
