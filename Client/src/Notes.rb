#Elten Code
#Copyright (C) 2014-2020 Dawid Pieper
#All rights reserved.

class Scene_Notes
  def main(index=0)
    if $name=="guest"
      alert(_("This section is unavailable for guests"))
      $scene=Scene_Main.new
      return
      end
  nt=srvproc("notes",{"get"=>"1"})
  if nt[0].to_i<0
    alert(_("Error"))
    $scene=Scene_Main.new
    return
    end
  t=0
  @notes=[]
  d=0
  for i in 2..nt.size-1
        case t
    when 0
      @notes[d]=Struct_Note.new(nt[i].to_i)
      t+=1
      when 1
     @notes[d].name=nt[i].delete("\r\n")
     t+=1
     when 2
       @notes[d].author=nt[i].delete("\r\n")
     t+=1
     when 3
     @notes[d].created=Time.at(nt[i].delete("\r\n").to_i)
     t+=1
     when 4
     @notes[d].modified=Time.at(nt[i].delete("\r\n").to_i)
     t+=1
     when 5
       if nt[i].delete("\r\n")=="\004END\004"
         t=0
         d+=1
       else
         @notes[d].text+=nt[i]
         end
    end
  end
  selt=[]
  for n in @notes
    selt.push(n.name+"\r\n#{p_("Notes", "Author")}: "+n.author+"\r\n#{p_("Notes", "Modified")}: "+sprintf("%04d-%02d-%02d %02d:%02d",n.modified.year,n.modified.month,n.modified.day,n.modified.hour,n.modified.min))
  end
  selt.push(p_("Notes", "New note"))
  @sel=Select.new(selt,true,index,p_("Notes", "Notes"))
  @sel.bind_context{|menu|context(menu)}
  loop do
    loop_update
    @sel.update
    $scene=Scene_Main.new if escape
    if enter
      if @sel.index==@notes.size
        $scene=Scene_Notes_New.new
      else
        show(@notes[@sel.index])
        @sel.focus if @refresh!=true
        end
              end
                        if $key[0x2e] and @sel.index<@notes.size and @notes[@sel.index].author==$name
      delete(@notes[@sel.index])
      end
              if @refresh == true
                    @refresh = false
                    main(@sel.index)
                    return
          end
      break if $scene!=self
    end
  end
  def context(menu)
    if @sel.index<@notes.size    
    note=@notes[@sel.index]
    menu.option(p_("Notes", "Read")) {
              show(note)
    }
    menu.option(p_("Notes", "Edit")) {
                show(note,true)
    }
    if note.author==$name
    menu.option(_("Delete")) {
                  delete(note)
    }
  end
  end
  menu.option(_("Refresh")) {
  main
  }
            end
  def show(note,edit=false)
    id=note.id
    shares=[]
nt=srvproc("notes",{"getshares"=>"1", "noteid"=>id})
if nt[0].to_i<0
  alert(_("Error"))
    return
end
if nt.size>1
for t in nt[1..nt.size-1]
  sh=t.delete("\r\n")
  sh=note.author if sh==$name
  shares.push(sh)
end
end
sharest=shares+[]
sharest.push(p_("Notes", "Add")) if note.author==$name
@fields=[Edit.new(note.name,"MULTILINE|READONLY",note.text,true),Button.new(p_("Notes", "Edit")),Select.new(sharest,true,0,p_("Notes", "Note shared with"),true),nil,Button.new(_("Cancel"))]
@form=Form.new(@fields)
if edit == true
@form.fields[0].flags=Edit::Flags::MultiLine
@form.fields[1]=Button.new(_("Save"))
end
@form.fields[3]=Button.new(_("Delete")) if note.author==$name
    dialog_open
loop do
  loop_update
  @form.update
  if escape or ((enter or space) and @form.index==4)
break
    end
  if ((enter or space) and @form.index==1)
    if edit == false
    edit=true
    @form.fields[0].flags=Edit::Flags::MultiLine
    @form.index=0
    @form.fields[0].focus
    @form.fields[1]=Button.new(_("Save"))
  else
    text=@form.fields[0].text_str
    bufid=buffer(text)
    nt=srvproc("notes",{"edit"=>"1", "buffer"=>bufid, "noteid"=>note.id})
                if nt[0].to_i<0
          alert(_("Error"))
        else
          alert(p_("Notes", "The note has been modified."))
          @refresh=true
          break
          end
    end
        end
  if enter and @form.index==2 and @form.fields[2].index==shares.size
    dialog_open
    inpt=Edit.new(p_("Notes", "Who do you want to share this note with?"))
    loop do
      loop_update
      inpt.update
      if escape
        dialog_close
        break
        end
      inpt.settext(selectcontact) if arrow_up or arrow_down
      if enter
        user=inpt.text_str.delete("\r\n").gsub("\004LINE\004","")
                user=finduser(user) if finduser(user).upcase==user.upcase
                if user_exist(user) == false
          alert(p_("Notes", "User cannot be found"))
        else
          nt=srvproc("notes",{"noteid"=>note.id, "addshare"=>"1", "user"=>user})
          if nt[0].to_i<0
            alert(_("Error"))
          else
            speech(p_("Notes", "From now on you share this note with %{user}")%{'user'=>user})
            speech_wait
            shares.push(user)
            sharest=shares+[p_("Notes", "Add")]
            @form.fields[2].commandoptions=sharest
            dialog_close
            break
            end
          end
        end
    end
    loop_update
  end
if $key[0x2e] and @form.index==2 and note.author==$name and @form.fields[2].index<shares.size
  if confirm(p_("Notes", "Do you want to stop sharing this note with %{user}?")%{'user'=>@form.fields[2].commandoptions[@form.fields[2].index]})==1
  user=shares[@form.fields[2].index]
            nt=srvproc("notes",{"noteid"=>note.id, "delshare"=>"1", "user"=>user})
          if nt[0].to_i<0
            alert(_("Error"))
          else
            speech(p_("Notes", "You no longer share this note with %{user}")%{'user'=>user})
                        shares.delete(user)
            sharest=shares+[p_("Notes", "Add")]
@form.fields[2].index-=1
@form.fields[2].index=0 if @form.fields[2].index<0
            @form.fields[2].commandoptions=sharest
            speech_wait
          end
        end
        @form.fields[2].focus
  end
if (enter or space) and @form.index==3
  if delete(note) == true
break
else
  @form.fields[3].focus
  end
  end
end
dialog_close
        end
def delete(note)
  id=note.id
  if confirm(p_("Notes", "Do you really want to delete %{name}?")%{'name' => note.name}) == 0
    return false
  else
    nt=srvproc("notes",{"delete"=>"1", "noteid"=>id})
    if nt[0].to_i<0
      alert(_("Error"))
      return false
    end
    alert(p_("Notes", "The note has been deleted."))
    @refresh=true
    speech_wait
    return true
        end
  end
        end

class Scene_Notes_New
  def main
    @fields=[Edit.new(p_("Notes", "note title"),"","",true),Edit.new(p_("Notes", "Note content"),"MULTILINE","",true),Button.new(p_("Notes", "Add")),Button.new(_("Cancel"))]
    @form=Form.new(@fields)
    btn=@form.fields[2]
    loop do
      loop_update
      if (@form.fields[0].text=="" or @form.fields[1].text=="") and @form.fields[2]!=nil
        btn=@form.fields[2]
        @form.fields[2]=nil
      elsif (@form.fields[0].text!="" and @form.fields[1].text!="") and @form.fields[2]==nil
        @form.fields[2]=btn
        end
      @form.update
      break if escape or ((enter or space) and @form.index==3)
      if ((enter or space) and @form.index==2)
        name=@form.fields[0].text_str
        text=@form.fields[1].text_str
        bufid=buffer(text)
        nt=srvproc("notes",{"create"=>"1", "notename"=>name, "buffer"=>bufid})
                if nt[0].to_i<0
          alert(_("Error"))
        else
          alert(p_("Notes", "The note has been created"))
          break
          end
        end
    end
    $scene=Scene_Notes.new
  end
  end

class Struct_Note
attr_accessor :id
attr_accessor :name
attr_accessor :text
attr_accessor :author
attr_accessor :modified
attr_accessor :created
def initialize(id=0)
  @id=id
  @created=Time.now
  @modified=Time.now
  @author=$name
  @text=""
  @name=""
end
end