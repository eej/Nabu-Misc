
## Two Button Controller Input on the Nabu

This is a simple CP/M program demonstrating two button input on the Nabu with a Sega Master System controller.

SMS Controllers wire button 2 to pin 9, which is a paddle input pin on the Nabu. Pushing the button causes the Nabu to raise a paddle interrupt. The interrupts aren't debounced, and you can only guess if they are caused by button up or button down changes. But just knowing there was activity is good enough to be useful in some games.
