require 'squib'
require 'pp'

data = Squib.csv(file: 'cards.csv')

def toTitleLayout(ty)
  case ty
  when "AGENDA"
    :card_agenda_name
  when "ASSET", "HARDWARE", "ICE", "RESOURCE", "UPGRADE"
    :card_name_right
  when "CORPID", "RUNNERID"
    :identity_name
  else
    :card_name_left
  end
end

def toBodyLayout(ty)
  case ty
  when "CORPID", "RUNNERID"
    :identity_text
  when "ICE"
    :card_ice_text
  else
    :card_text
  end
end

def toCardFile(ty, f)
  case ty
  when "ICE"
    "UI/Corp#{f}ICE.png"
  when "CORPID"
    "UI/Corp#{f}Identity.png"
  when "RUNNERID"
    "UI/Runner#{f}Identity.png"
  when "CORPID", "AGENDA", "ASSET", "UPGRADE", "OPERATION"
    "UI/Corp#{f}#{ty.capitalize()}.png"
  else
    "UI/Runner#{f}#{ty.capitalize()}.png"
  end
end

# NOTE: This is fragile with <flavor> tags.
# These tags must appear at the beginning or end of a line.
# If they are elsewhere, then you will end up with weird and possibly malformed XML.
# <flavor> tags can be spread over multiple lines, however.
def formatText(tx)
  formatted = tx
    .gsub("&", "&amp;")
    .gsub("<flavor>", "<small><i>").gsub("</flavor>", "</i></small>")
    .gsub("<em>", "<i>").gsub("</em>", "</i>")
    .gsub(":credit:", "<span font='NiseiNetrunner'>R</span>")
    .gsub(":subroutine:", "<span font='NiseiNetrunner'>B</span>")
    .gsub(":click:", "<span font='NiseiNetrunner'>K</span>")
    .gsub(":interrupt:", "<span font='NiseiNetrunner'>I</span>")
    .gsub(":trash:", "<span font='NiseiNetrunner'>T</span>")
    .gsub(/:(\d)[mM][uU]:/, '\1<span font="NiseiNetrunner">U</span>')
    .gsub(/:[xX][mM][uU]:/, 'X<span font="NiseiNetrunner">U</span>')
    .gsub(":link:", "<span font='NiseiNetrunner'>L</span>")
    .gsub(":recurring:", "<span font='NiseiNetrunner'>E</span>")
    .gsub(/:[dD][xX]:/, "<span font='NiseiNetrunner'>0</span>")
    .gsub(/:[dD](\d):/, '<span font="NiseiNetrunner">\1</span>')
    .gsub("R&D", "R&amp;D")
    .gsub("<del>", "<span strikethrough='true'>").gsub("</del>", "</span>")
    .gsub("\n", "")
    .gsub("(br)", "</span>\n<span line_height='0.3'>\n</span><span>")
    .gsub("<br />", "</span>\n<span>")
    .gsub("(bbr)", "</span>\n<span line_height='0.5'>\n</span><span>")
  res = "<span>" + formatted + "</span>"
  # This allows multi-line flavour tags, e.g. if we have
  # <flavor>This is some flavour text.(br)
  # But then it was on another line.</flavor>
  # Then res becomes:
  # <span><small><i>This is some flavour text.</span><span line_height=...></span>
  # <span>But then it was on another line.</i></small></span>
  # Which has the small/i tags closed incorrectly since the /span is encountered first.
  # We therefore move those outwards, so:
  # <small><i><span>This is some flavour text.</span><span line_height=...></span>
  # <span>But then it was on another line.</span></i></small>
  res
    .gsub("<span><small><i>", "<small><i><span>")
    .gsub("</i></small></span>", "</span></i></small>")
end

def prependUnique(name, uniq)
  name = name.gsub("R&D", "R&amp;D")
  if uniq == "Yes" then
    "<span font='NiseiNetrunner' baseline_shift='-5pt'>M</span>" + name
  else name end
end

def typeLine(data)
  def makeTypeLine(ty, sub1, sub2, sub3)
    subs = [sub1, sub2, sub3].compact.join(" - ")
    "#{ty}#{if subs.length > 0 then ":" else "" end} <span font='KimberleyW00-Light'>#{subs}</span>"
  end
  res = data['Type'].zip(data['Subtype1'], data['Subtype2'], data['Subtype3']).map do |t, s1, s2, s3|
    case t
    when "CORPID", "RUNNERID"
      [makeTypeLine("IDENTITY", s1, s2, s3), :identity_type]
    when "ICE"
      [makeTypeLine(t, s1, s2, s3), :card_ice_type]
    else
      [makeTypeLine(t, s1, s2, s3), :card_type]
    end
  end 
  typeline = res.transpose
  text str: typeline[0], layout: typeline[1], markup: true
end

def shadow_text(txt, lay)
  text str: txt, layout: lay, stroke_width: 7.0
  text str: txt, layout: lay, color: "white"
end

def attr_string(design, art)
  str = ""
  if not art.nil? then str = "Illus. #{art}, " end
  if not design.nil? then str = "#{str}Design. #{design}" else str = str[0..-3] end
  str
end

def attr_layout(ty)
  case ty
  when "ICE"
    :card_ice_attribution
  when "PROGRAM"
    :card_program_attribution
  when "RUNNERID"
    :identity_runner_attribution
  else
    :card_attribution
  end
end

def set_layout(ty)
  case ty
  when "ICE"
    :card_ice_set
  when "PROGRAM"
    :card_program_set
  when "RUNNERID"
    :identity_runner_set
  else
    :card_set
  end
end

# TODO:
# Look at :credit: spacing and width of :dX: outline
# Make new overlays for full art cards, or find alternative templates
# Add in Ams' little credit icon in the cost bubble

Squib::Deck.new(cards: data['Name'].size, layout: 'base_layout.yml', width: 820, height: 1115) do
  png file: data['ImageName'].map {|n| if n.nil? then nil else "Art/#{n}.png" end}, layout: :card_art
  png file: data['Type'].zip(data['Faction']).map { |t,f| toCardFile(t, f) }
  text str: data['DesignCred'].zip(data['ArtCred']).map {|d,a| attr_string(d,a)},
       layout: data['Type'].map {|t| attr_layout(t)}
  text(str: data['SetText'].zip(data['Version'], data['Quantity']).map {|t,v,q| if t.nil? then "" else "#{":q:" * q} :seticon: #{t} (v#{v})" end},
       layout: data['Type'].map {|t| set_layout(t)}) do |embed|
          embed.png key: ':seticon:', file: "UI/set.png", width: 25, height: 25, dy: -21
          embed.png key: ':q:', file: "UI/quantity.png", width: 19, height: 25, dy: -21
       end
  text str: data['Name'].zip(data['Unique']).map { |n,u| prependUnique(n, u) },
       markup: true, layout: data['Type'].map { |t| toTitleLayout(t) }
  text str: data['Text'].map { |tx| formatText(tx) }, font_size: data['FontSize'],
       markup: true, layout: data['Type'].map { |t| toBodyLayout(t) }
  text str: data['Cost'].zip(data['Type']).map {|c,t| c}, layout: :card_cost, markup: true
  shadow_text(data['Advancements'], :card_agenda_advancement)
  shadow_text(data['AgendaPoints'], :card_agenda_point)
  typeLine(data)
  text str: data['STR'],
       layout: data['Type'].map {|t| if t == "ICE" then :card_ice_str else :card_program_str end}
  text str: data['DeckCount'], layout: data['Type'].map {|t| if t == "CORPID" then :identity_corp_deckmin else :identity_runner_deckmin end}
  png file: "UI/TrashCost.png", layout: data['Type'].map {|t| if t == "ICE" then :card_ice_icon_trash else :card_icon_trash end},
      range: data['TrashCost'].filter_map.with_index {|e, i| i if not e.nil?}
  text str: data['TrashCost'], layout: data['Type'].map {|t| if t == "ICE" then :card_ice_trash else :card_trash end}
  text str: data['MU'], layout: :card_program_mu
  text str: data['Type'].zip(data['MU']).map {|ty, mu| if ty == "RUNNERID" then if mu.nil? then 4 else mu end end}, layout: :identity_runner_mu
  text str: data['Link'], layout: :identity_runner_link
  text str: data['Subtitle'], layout: data['Type'].map {|ty| if ty == "RUNNERID" then :identity_runner_subtitle else :identity_corp_subtitle end}
  text str: data['Influence'], layout: data['Type'].map {|ty| if ty == "RUNNERID" then :identity_runner_influence else :identity_corp_influence end},
       range: data['Type'].filter_map.with_index {|t, i| i if t == "CORPID" or t == "RUNNERID"}
  png file: data['Type'].zip(data['Influence']).map {|ty, inf| if ty != "RUNNERID" and ty != "CORPID" then if inf.nil? then nil else "UI/Influence#{inf}.png" end end},
      layout: data['Side'].zip(data['Type']).map {|side, ty| if ty == "ICE" then :card_ice_infpip elsif side == "Corp" then :card_corp_infpip else :card_runner_infpip end}
  # Jigsaw icons
  png file: "UI/jigsaw.png", layout: :jigsaw_up, range: data['Jigsaw'].filter_map.with_index {|e, i| i if (not e.nil?) and e.include? "U"}
  png file: "UI/jigsaw.png", layout: :jigsaw_down, range: data['Jigsaw'].filter_map.with_index {|e, i| i if (not e.nil?) and e.include? "D"}
  png file: "UI/jigsaw.png", layout: :jigsaw_left, range: data['Jigsaw'].filter_map.with_index {|e, i| i if (not e.nil?) and e.include? "L"}
  png file: "UI/jigsaw.png", layout: :jigsaw_right, range: data['Jigsaw'].filter_map.with_index {|e, i| i if (not e.nil?) and e.include? "R"}
  png file: data['Overlay'].map {|n| if n.nil? then nil else "Overlays/#{n}.png" end}, layout: :card_art
  save format: :png, trim: '0.125in'
  save_pdf trim: '0.125in', file: "output.pdf"
end
