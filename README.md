# unset-render

This is the renderer that we use for the Warwick Netrunner unset, un-derachievers. It also works as a renderer for regular Netrunner cards with a few nice extra features!

## How do I install this?

You need a working install of Ruby, including `rake` and `gem`. Install [Squib](http://squib.rocks/) via `gem install squib`. The generator is run with `rake`, which dumps card images and a PDF into the `_output` directory.

You will also need some fonts for the renderer to fully work: Minion Pro, Minion Regular SC, Monkirta Pursuit, Kimberley and the NiseiNetrunner (it's an old font) font provided in this repository.

## What features does it have?

* Render cards from a spreadsheet using [RecklessKat's amazing templates](https://drive.google.com/drive/folders/1RaM2SsadeKytis-e-NcNQHxfs-LCghC4?usp=sharing).
* The text boxes of these cards can be formatted using inline HTML, and have support for inline Netrunner symbols using codes like `:credit:`.
* Render _overlays_, which allow you to draw over the card being rendered to add features to it. This allows you to add art elements which overlap the text box, so that the art pops out of its usual window.
* Render _jigsaw icons_, which are present in the unset. These icons appear on the edges of the card and allow cards to be "attached" to each other. If you're making regular cards, you don't need to worry about this.
* Render _dice glyphs_, which are present in the unset. Using codes like `:d4:`, you can render dice inline in the text box of your card.

## How do I use this renderer?

In short, provide a file called `cards.csv` containing data about your cards. An example spreadsheet, which you can export to CSV and use with this renderer, is available on [Google Sheets](https://docs.google.com/spreadsheets/d/110ln-G-0z_3clYbJ2-xva4Bpb3JBNs89EIb4I-KsFKQ/edit?usp=sharing). This uses a similar format to [MNemic's Custom Card Generator](https://www.reddit.com/r/Netrunner/comments/fh754l/mnemics_custom_card_generator_for_android/), but we list the full format for completeness below. The dropdowns on the Google Sheet should provide all the options you need.

* **Set Text**: The little code to go next to the set icon. The set icon currently cannot be customised.
* **Side**: Corp or Runner.
* **Faction**: Which faction this card belongs to (and thus what template we use to render it).
* **Type**: The type of card (e.g. agenda).
* **Subtype1** to **Subtype3**: The (up to three) subtypes on the card. They will be combined correctly when the card is rendered.
* **Unique**: Whether the card is unique (Yes) or not (No).
* **DeckCount**: The minimum deck size of an identity. This is ignored on any non-identity cards.
* **Influence**: The influence cost of the card.
* **Cost**, **TrashCost**, **STR**, **MU**, **Advancements**, **AgendaPoints** and **Link**: Those corresponding features of the card. Ignored on cards where this doesn't make sense.
* **Name**: The title of the card.
* **Subtitle**: An identity's subtitle, e.g. "Eco-Insurrectionist" for Esâ Afontov.
* **Text**: The text box of the card. Allows formatting (see the next bullet pointed list).
* **FontSize**: The font size of the text box. Due to awkward reasons involving Pango (which is used to render the card), you need to manually provide a font size. This defaults to 8pt, which should be fine for most cards, but you may provide an alternative value.
* **ArtCred** and **DesignCred**: The credits for the artist/designer of the card.
* **ImageName**: The name of the image to render. The image will be drawn in full underneath the relevant template, so needs to be the same size as a card image (820x1114px). See RecklessKat's documentation for templates for each card type.
* **Overlay**: The name of the image to render _above_ the template, so will cover the text box. It should therefore be mostly transparent.
* **Quantity**: Currently ignored by the renderer.
* **Version**: Renders a little version number in the corner, so you can track what version of a card you're playing with.
* **Jigsaw**: Renders jigsaw icons on the up (U), left (L), down (D) and right (R) edges of the card depending on what you specify here - e.g. UDL means draw a jigsaw icon on the up, down and left edges. Leave blank if you do not want any edges.

The **Text** field allows your text to be formatted using the following HTML tags:

* `<em>...</em>` renders the contained text in italics.
* `<b>...</b>` renders the contained text in bold.
* `<del>...</del>` renders the contained text in strikethrough.
* `<flavor>...</flavor>` renders the text smaller and in italics (as flavour text). This is the only tag that is allowed to be multiline, but must appear only at the start or end of a line - e.g. you can't have `blah <flavor>small</flavor> blah2` as the flavour text must be on its own line.

and allows for the following special codes for Netrunner symbols:

* `:credit:`, `:subroutine:`, `:click:`, `:interrupt:`, `:trash:`, `:link:`, `:recurring:` render the game icons you'd expect.
* `:NMU:` (for some N) renders N followed by the MU symbol.
* `:dN:` (for some N) renders a six-sided die showing N.
* `:dX:` renders a die showing the letter X.
* Line breaks are rendered with `<br />` (for a single linebreak without additional spacing), `(br)` (for breaks between clauses on the card) and `(bbr)` (for larger breaks, e.g. the gap between rules text and flavour text).