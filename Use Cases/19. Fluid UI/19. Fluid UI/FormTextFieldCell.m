//
//  FormTextFieldCell.m
//  19. Fluid UI
//
//  Created by Stephen Fortune on 28/12/2014.
//  Copyright (c) 2014 IceCube Software Ltd. All rights reserved.
//

#import "FormTextFieldCell.h"

@implementation FormTextFieldCell

-(void) setTextField:(TableViewCellAwareTextField *)textField{

    _textField = textField;
    _textField.parentCell = self;
}

-(void) awakeFromNib{
    
    [super awakeFromNib];
    
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
}

@end