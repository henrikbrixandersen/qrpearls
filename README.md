QR Pearls
=========
Perl Web App for Generating QR Code Beads Designs

Motivation
----------
The QR Pearls web app was written to be used in the Tech Lab at [Aarhus Hovedbibliotek](http://www.aakb.dk/biblioteker/hovedbiblioteket) installation in February, 2013.
The Tech Lab installation is a collaboration between [Aarhus Folkelab](http://www.folkelab.dk/) and [Open Space Aarhus](http://www.osaa.dk/).

Features
--------
* Automatic or manual QR code version selection
* QR code error correction level selection
* Preview of generated QR code
* Generates PDF file with beads design
* Mirrored beads design, so QR code is ironed on the back, not the front
* UTF-8 text string support

Limitations
-----------
* Generated design is intended for use with 29x29 peg boards (e.g. product code [234](http://www.hamabeads.com/large_square_679.htm) from Hama Beads)

License
-------
The generated QR codes are of course free to use, no license restrictions at all. The source code of the QR Pearls web app is available under the [2-clause BSD license](http://opensource.org/licenses/BSD-2-Clause).

The project uses a number of third party libraries, each with their own licensing information:
* [jQuery](http://jquery.com)
* [Bootstrap](http://twitter.github.com/bootstrap/)
* [I18N::AcceptLanguage](http://search.cpan.org/dist/I18N-AcceptLanguage/)
* [libintl-perl](http://search.cpan.org/dist/libintl-perl/)
* [HTML::Template](http://search.cpan.org/dist/HTML-Template/)
* [HTML::Template::Expr](http://search.cpan.org/dist/HTML-Template-Expr/)
* [Imager::QRCode](http://search.cpan.org/dist/Imager-QRCode/)
* [SVG](http://search.cpan.org/dist/SVG/)
* [PDF::API2](http://search.cpan.org/dist/PDF-API2/)

Configuration
-------------
QR Pearls is intended to run under the [Apache](http://httpd.apache.org/) HTTP Server with [mod_perl2](http://perl.apache.org/) and [mod_rewrite](http://httpd.apache.org/docs/current/mod/mod_rewrite.html).
Below is an example configuration for a virtual host running QR Pearls:

```
<VirtualHost *:80>
  ServerName foo.bar.com

	PerlSwitches -T
	PerlModule ModPerl::Registry

	DocumentRoot /var/www/foo.bar.com/docs
	<Directory /var/www/foo.bar.com/docs>
		AllowOverride None
		Options MultiViews SymlinksIfOwnerMatch ExecCGI

		PerlOptions +ParseHeaders
		PerlResponseHandler ModPerl::Registry
		PerlSetEnv BASE_DIRECTORY /var/www/foo.bar.com

		DirectoryIndex index.pl
		AddHandler perl-script .pl

		RewriteEngine On
		RewriteBase /
		RewriteRule ^index\.pl$ - [L]
		RewriteRule ^qrcode\.pl$ - [L]
		RewriteCond %{REQUEST_FILENAME} !-f
		RewriteCond %{REQUEST_FILENAME} !-d
		RewriteRule ^(.*[^/])[/]?$ /index.pl?page=$1 [L]

		Order allow,deny
		Allow from all
	</Directory>
</VirtualHost>
```
