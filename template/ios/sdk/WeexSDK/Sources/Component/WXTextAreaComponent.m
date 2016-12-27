/**
 * Created by Weex.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the Apache Licence 2.0.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import "WXTextAreaComponent.h"
#import "WXUtility.h"
#import "WXConvert.h"
#import "WXComponent_internal.h"
#import "WXView.h"
#import "WXSDKInstance.h"

@interface WXTextAreaView : UITextView
@property (nonatomic, assign) UIEdgeInsets border;
@property (nonatomic, assign) UIEdgeInsets padding;
@end

@implementation WXTextAreaView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _padding = UIEdgeInsetsZero;
        _border = UIEdgeInsetsZero;
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    bounds.size.width -= self.padding.left + self.border.left;
    bounds.origin.x += self.padding.left + self.border.left;
    
    bounds.size.height -= self.padding.top + self.border.top;
    bounds.origin.y += self.padding.top + self.border.top;
    
    bounds.size.width -= self.padding.right + self.border.right;
    
    bounds.size.height -= self.padding.bottom + self.border.bottom;
    
    return bounds;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

@end

@interface WXTextAreaComponent()
@property (nonatomic, strong) WXTextAreaView *textView;
@property (nonatomic, strong) UILabel *placeholder;

//attribute
@property (nonatomic, strong) UIColor *placeholderColor;
@property (nonatomic, strong) NSString *placeholderString;
@property (nonatomic, strong) UILabel *placeHolderLabel;
@property (nonatomic) BOOL autofocus;
@property (nonatomic) BOOL disabled;
@property (nonatomic, strong)NSString *textValue;
@property (nonatomic) NSUInteger rows;
//style
@property (nonatomic) WXPixelType fontSize;
@property (nonatomic) WXTextStyle fontStyle;
@property (nonatomic) WXTextWeight fontWeight;
@property (nonatomic, strong) NSString *fontFamily;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic) NSTextAlignment textAlign;
//event
@property (nonatomic) BOOL inputEvent;
@property (nonatomic) BOOL focusEvent;
@property (nonatomic) BOOL blurEvent;
@property (nonatomic) BOOL changeEvent;
@property (nonatomic) BOOL clickEvent;
@property (nonatomic, strong) NSString *changeEventString;
@property (nonatomic, assign) CGSize keyboardSize;
@property (nonatomic, assign) CGRect rootViewOriginFrame;

@end

@implementation WXTextAreaComponent {
    UIEdgeInsets _border;
    UIEdgeInsets _padding;
    NSTextStorage* _textStorage;
}

WX_EXPORT_METHOD(@selector(focus))
WX_EXPORT_METHOD(@selector(blur))

- (instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance
{
    self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance];
    if (self) {
        _inputEvent = NO;
        _focusEvent = NO;
        _blurEvent = NO;
        _changeEvent = NO;
        _clickEvent = NO;
        
        if (attributes[@"autofocus"]) {
            _autofocus = [attributes[@"autofocus"] boolValue];
        }
        if (attributes[@"rows"]) {
            _rows = [attributes[@"rows"] integerValue];
        } else {
            _rows = 2;
        }
        if (attributes[@"disabled"]) {
            _disabled = [attributes[@"disabled"] boolValue];
        }
        if (attributes[@"placeholder"]) {
            NSString *placeHolder = [WXConvert NSString:attributes[@"placeholder"]];
            if (placeHolder) {
                _placeholderString = placeHolder;
            }
        }
        if (!_placeholderString) {
            _placeholderString = @"";
        }
        if (styles[@"placeholderColor"]) {
            _placeholderColor = [WXConvert UIColor:styles[@"placeholderColor"]];
        }else {
            _placeholderColor = [UIColor colorWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1.0];
        }
        if (attributes[@"value"]) {
            NSString * value = [WXConvert NSString:attributes[@"value"]];
            if (value) {
                _textValue = value;
                if([value length] > 0) {
                    _placeHolderLabel.text = @"";
                }
            }
        }
        if (styles[@"color"]) {
            _color = [WXConvert UIColor:styles[@"color"]];
        }
        if (styles[@"fontSize"]) {
            _fontSize = [WXConvert WXPixelType:styles[@"fontSize"]];
        }
        if (styles[@"fontWeight"]) {
            _fontWeight = [WXConvert WXTextWeight:styles[@"fontWeight"]];
        }
        if (styles[@"fontStyle"]) {
            _fontStyle = [WXConvert WXTextStyle:styles[@"fontStyle"]];
        }
        if (styles[@"fontFamily"]) {
            _fontFamily = styles[@"fontFamily"];
        }
        if (styles[@"textAlign"]) {
            _textAlign = [WXConvert NSTextAlignment:styles[@"textAlign"]] ;
        }
        
        _padding = UIEdgeInsetsZero;
        _border = UIEdgeInsetsZero;
        UIEdgeInsets padding = UIEdgeInsetsMake(self.cssNode->style.padding[CSS_TOP], self.cssNode->style.padding[CSS_LEFT], self.cssNode->style.padding[CSS_BOTTOM], self.cssNode->style.padding[CSS_RIGHT]);
        if (!UIEdgeInsetsEqualToEdgeInsets(padding, _padding)) {
            _padding = padding;
        }
        UIEdgeInsets border = UIEdgeInsetsMake(self.cssNode->style.border[CSS_TOP], self.cssNode->style.border[CSS_LEFT], self.cssNode->style.border[CSS_BOTTOM], self.cssNode->style.border[CSS_RIGHT]);
        if (!UIEdgeInsetsEqualToEdgeInsets(border, _border)) {
            _border = border;
        }
        _rootViewOriginFrame = CGRectNull;
    }
    
    return self;
}

- (void)viewWillLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillUnload
{
    _textView = nil;
}
- (UIView *)loadView
{
    return [[WXTextAreaView alloc] initWithFrame:[UIScreen mainScreen].bounds];
}
- (void)viewDidLoad
{
    _textView = (WXTextAreaView*)self.view;
    [self setEnabled];
    [self setAutofocus];
    if (_placeholderString) {
        _placeHolderLabel = [[UILabel alloc] init];
        _placeHolderLabel.numberOfLines = 0;
        [_textView addSubview:_placeHolderLabel];
    }
    [self setPlaceholderAttributedString];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
    toolbar.items = [NSArray arrayWithObjects:space, barButton, nil];
    
    _textView.inputAccessoryView = toolbar;
    
    if (_textValue && [_textValue length]>0) {
        _textView.text = _textValue;
        _placeHolderLabel.text = @"";
    }else {
        _textView.text = @"";
    }
    _textView.delegate = self;
    
    if (_color) {
        [_textView setTextColor:_color];
    }
    [_textView setTextAlignment:_textAlign];
    [self setTextFont];
    [_textView setBorder:_border];
    [_textView setPadding:_padding];
    
    [_textView setNeedsDisplay];
    [_textView setClipsToBounds:YES];
}

-(void)focus
{
    if (self.textView) {
        [self.textView becomeFirstResponder];
    }
}

-(void)blur
{
    if (self.textView) {
        [self.textView resignFirstResponder];
    }
}

#pragma mark - private method
-(UIColor *)convertColor:(id)value
{
    UIColor *color = [WXConvert UIColor:value];
    if(value) {
        NSString *str = [WXConvert NSString:value];
        if(str && [@"" isEqualToString:str]) {
            color = [UIColor blackColor];
        }
    }else {
        color = [UIColor blackColor];
    }
    return color;
}

#pragma mark - add-remove Event
- (void)addEvent:(NSString *)eventName
{
    if ([eventName isEqualToString:@"input"]) {
        _inputEvent = YES;
    }
    if ([eventName isEqualToString:@"focus"]) {
        _focusEvent = YES;
    }
    if ([eventName isEqualToString:@"blur"]) {
        _blurEvent = YES;
    }
    if ([eventName isEqualToString:@"change"]) {
        _changeEvent = YES;
    }
    if ([eventName isEqualToString:@"click"]) {
        _clickEvent = YES;
    }
}

-(void)removeEvent:(NSString *)eventName
{
    if ([eventName isEqualToString:@"input"]) {
        _inputEvent = NO;
    }
    if ([eventName isEqualToString:@"focus"]) {
        _focusEvent = NO;
    }
    if ([eventName isEqualToString:@"blur"]) {
        _blurEvent = NO;
    }
    if ([eventName isEqualToString:@"change"]) {
        _changeEvent = NO;
    }
    if ([eventName isEqualToString:@"click"]) {
        _clickEvent = NO;
    }
}

#pragma mark - upate attributes
- (void)updateAttributes:(NSDictionary *)attributes
{
    if (attributes[@"autofocus"]) {
        _autofocus = [attributes[@"autofocus"] boolValue];
        [self setAutofocus];
    }
    if (attributes[@"disabled"]) {
        _disabled = [attributes[@"disabled"] boolValue];
        [self setEnabled];
    }
    if (attributes[@"placeholder"]) {
        _placeholderString = attributes[@"placeholder"];
        [self setPlaceholderAttributedString];
    }
    if (attributes[@"value"]) {
        NSString * value = [WXConvert NSString:attributes[@"value"]];
        if (value) {
            _textValue = value;
            _textView.text = _textValue;
            if([value length] > 0) {
                _placeHolderLabel.text = @"";
            }
        }
    }
}

#pragma mark - upate styles
- (void)updateStyles:(NSDictionary *)styles
{
    if (styles[@"color"]) {
        _color = [WXConvert UIColor:styles[@"color"]];
        [_textView setTextColor:_color];
    }
    if (styles[@"fontSize"]) {
        _fontSize = [WXConvert WXPixelType:styles[@"fontSize"]];
    }
    if (styles[@"fontWeight"]) {
        _fontWeight = [WXConvert WXTextWeight:styles[@"fontWeight"]];
    }
    if (styles[@"fontStyle"]) {
        _fontStyle = [WXConvert WXTextStyle:styles[@"fontStyle"]];
    }
    if (styles[@"fontFamily"]) {
        _fontFamily = styles[@"fontFamily"];
    }
    
    [self setTextFont];
    
    if (styles[@"textAlign"]) {
        _textAlign = [WXConvert NSTextAlignment:styles[@"textAlign"]] ;
        [_textView setTextAlignment:_textAlign];
    }
    if (styles[@"placeholderColor"]) {
        _placeholderColor = [WXConvert UIColor:styles[@"placeholderColor"]];
    }else {
        _placeholderColor = [UIColor colorWithRed:0x99/255.0 green:0x99/255.0 blue:0x99/255.0 alpha:1.0];
    }
    [self setPlaceholderAttributedString];
    
    UIEdgeInsets padding = UIEdgeInsetsMake(self.cssNode->style.padding[CSS_TOP], self.cssNode->style.padding[CSS_LEFT], self.cssNode->style.padding[CSS_BOTTOM], self.cssNode->style.padding[CSS_RIGHT]);
    if (!UIEdgeInsetsEqualToEdgeInsets(padding, _padding)) {
        _padding = padding;
    }
    
    UIEdgeInsets border = UIEdgeInsetsMake(self.cssNode->style.border[CSS_TOP], self.cssNode->style.border[CSS_LEFT], self.cssNode->style.border[CSS_BOTTOM], self.cssNode->style.border[CSS_RIGHT]);
    if (!UIEdgeInsetsEqualToEdgeInsets(border, _border)) {
        _border = border;
        [_textView setBorder:_border];
    }
}

#pragma mark measure frame
- (CGSize (^)(CGSize))measureBlock
{
    __weak typeof(self) weakSelf = self;
    return ^CGSize (CGSize constrainedSize) {
        
        CGSize computedSize = [[[NSString alloc] init]sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont systemFontSize]]}];
        computedSize.height = computedSize.height * _rows;
        //TODO:more elegant way to use max and min constrained size
        if (!isnan(weakSelf.cssNode->style.minDimensions[CSS_WIDTH])) {
            computedSize.width = MAX(computedSize.width, weakSelf.cssNode->style.minDimensions[CSS_WIDTH]);
        }
        
        if (!isnan(weakSelf.cssNode->style.maxDimensions[CSS_WIDTH])) {
            computedSize.width = MIN(computedSize.width, weakSelf.cssNode->style.maxDimensions[CSS_WIDTH]);
        }
        
        if (!isnan(weakSelf.cssNode->style.minDimensions[CSS_HEIGHT])) {
            computedSize.width = MAX(computedSize.height, weakSelf.cssNode->style.minDimensions[CSS_HEIGHT]);
        }
        
        if (!isnan(weakSelf.cssNode->style.maxDimensions[CSS_HEIGHT])) {
            computedSize.width = MIN(computedSize.height, weakSelf.cssNode->style.maxDimensions[CSS_HEIGHT]);
        }
        
        return (CGSize) {
            WXCeilPixelValue(computedSize.width),
            WXCeilPixelValue(computedSize.height)
        };
    };
}

#pragma mark textview Delegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    _changeEventString = [textView text];
    if (_focusEvent) {
        [self fireEvent:@"focus" params:nil];
    }
    if (_clickEvent) {
        [self fireEvent:@"click" params:nil];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if(textView.text && [textView.text length] > 0){
        _placeHolderLabel.text = @"";
    }else{
        [self setPlaceholderAttributedString];
    }
    if (textView.markedTextRange == nil) {
        if (_inputEvent) {
            [self fireEvent:@"input" params:@{@"value":[textView text]} domChanges:@{@"attrs":@{@"value":[textView text]}}];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (![textView.text length]) {
        [self setPlaceholderAttributedString];
    }
    if (_changeEvent) {
        if (![[textView text] isEqualToString:_changeEventString]) {
            [self fireEvent:@"change" params:@{@"value":[textView text]} domChanges:@{@"attrs":@{@"value":[textView text]}}];
        }
    }
    if (_blurEvent) {
        [self fireEvent:@"blur" params:nil];
    }
}

#pragma mark - set properties
- (void)setPlaceholderAttributedString
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:_placeholderString];
    UIFont *font = [WXUtility fontWithSize:_fontSize textWeight:_fontWeight textStyle:_fontStyle fontFamily:_fontFamily];
    if (_placeholderColor) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:_placeholderColor range:NSMakeRange(0, _placeholderString.length)];
        [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, _placeholderString.length)];
    }
    _placeHolderLabel.backgroundColor = [UIColor clearColor];
    CGRect expectedLabelSize = [attributedString boundingRectWithSize:(CGSize){self.view.frame.size.width, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    
    _placeHolderLabel.clipsToBounds = NO;
    CGRect newFrame = _placeHolderLabel.frame;
    newFrame.size.height = ceil(expectedLabelSize.size.height);
    newFrame.size.width = _textView.frame.size.width;
    newFrame.origin.y = 6;
    _placeHolderLabel.frame = newFrame;
    _placeHolderLabel.attributedText = attributedString;
}

- (void)setAutofocus
{
    if (_autofocus) {
        [_textView becomeFirstResponder];
    } else {
        [_textView resignFirstResponder];
    }
}

- (void)setTextFont
{
    UIFont *font = [WXUtility fontWithSize:_fontSize textWeight:_fontWeight textStyle:_fontStyle fontFamily:_fontFamily];
    [_textView setFont:font];
}

- (void)setEnabled
{
    _textView.editable = !(_disabled);
    _textView.selectable = !(_disabled);
}

#pragma mark keyboard
- (void)keyboardWasShown:(NSNotification*)notification
{
    if(![_textView isFirstResponder]) {
        return;
    }
    CGRect begin = [[[notification userInfo] objectForKey:@"UIKeyboardFrameBeginUserInfoKey"] CGRectValue];
    
    CGRect end = [[[notification userInfo] objectForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    if(begin.size.height <= 44 ){
        return;
    }
    _keyboardSize = end.size;
    UIView * rootView = self.weexInstance.rootView;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (CGRectIsNull(_rootViewOriginFrame)) {
        _rootViewOriginFrame = rootView.frame;
    }
    CGRect keyboardRect = (CGRect){
        .origin.x = 0,
        .origin.y = CGRectGetMaxY(screenRect) - _keyboardSize.height - 54,
        .size = _keyboardSize
    };
    CGRect textAreaFrame = [_textView.superview convertRect:_textView.frame toView:rootView];
    if (keyboardRect.origin.y - textAreaFrame.size.height <= textAreaFrame.origin.y) {
        [self setViewMovedUp:YES];
        self.weexInstance.isRootViewFrozen = YES;
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    if (![_textView isFirstResponder]) {
        return;
    }
    UIView * rootView = self.weexInstance.rootView;
    if (rootView.frame.origin.y < 0) {
        [self setViewMovedUp:NO];
        self.weexInstance.isRootViewFrozen = NO;
    }
}

- (void)closeKeyboard
{
    [_textView resignFirstResponder];
}

#pragma mark method
- (void)setViewMovedUp:(BOOL)movedUp
{
    UIView *rootView = self.weexInstance.rootView;
    CGRect rect = _rootViewOriginFrame;
    CGRect rootViewFrame = rootView.frame;
    CGRect textAreaFrame = [_textView.superview convertRect:_textView.frame toView:rootView];
    if (movedUp) {
        CGFloat offset =textAreaFrame.origin.y-(rootViewFrame.size.height-_keyboardSize.height-textAreaFrame.size.height);
        if (offset > 0) {
            rect = (CGRect){
                .origin.x = 0.f,
                .origin.y = -offset,
                .size = rootViewFrame.size
            };
        }
    }else {
        // revert back to the origin state
        rect = _rootViewOriginFrame;
        _rootViewOriginFrame = CGRectNull;
    }
    self.weexInstance.rootView.frame = rect;
}

#pragma mark -reset color
- (void)resetStyles:(NSArray *)styles
{
    if ([styles containsObject:@"color"]) {
        _color = [UIColor blackColor];
        [_textView setTextColor:[UIColor blackColor]];
    }
    if ([styles containsObject:@"fontSize"]) {
        _fontSize = WX_TEXT_FONT_SIZE;
        [self setTextFont];
    }
}

@end
