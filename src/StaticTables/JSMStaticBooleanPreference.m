//
// Copyright © 2014 Daniel Farrelly
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// *	Redistributions of source code must retain the above copyright notice, this list
//		of conditions and the following disclaimer.
// *	Redistributions in binary form must reproduce the above copyright notice, this
//		list of conditions and the following disclaimer in the documentation and/or
//		other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "JSMStaticBooleanPreference.h"

@implementation JSMStaticBooleanPreference

#pragma mark - User Interface

@synthesize control = _control;

- (UIControl *)control {
    if( _control == nil ) {
        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.on = self.boolValue;
        [toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
        _control = (UIControl *)toggle;
    }
    return _control;
}

- (UISwitch *)toggle {
    return (UISwitch *)self.control;
}

#pragma mark - Updating the value

- (BOOL)boolValue {
    return self.value.boolValue;
}

- (void)setBoolValue:(BOOL)boolValue {
    self.value = [NSNumber numberWithBool:boolValue];
}

- (void)valueDidChange {
    if( self.toggle.on != self.boolValue ) {
        [self.toggle setOn:self.boolValue animated:YES];
    }
}

#pragma mark - Event Handling

- (void)toggleChanged:(UISwitch *)toggle {
    self.value = [NSNumber numberWithBool:toggle.on];
}

@end
