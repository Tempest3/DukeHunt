<%@ WebHandler Language="C#" Class="DukeHunt" Debug="true" %>

using System;
using System.Web;
using System.Collections;
using System.IO;

class Entity
{

    public const int MARGIN = 50;

    private int id;
    private double x, y;
    private ImageInfo image;
    private int dir, speed;
    protected string audio;
    private bool alive;

    protected DukeGame game; // references the DukeGame instance 

    private static Random gen = new Random();

    private static int nextId = 0; // used to generate unique ID's

    // Creates the image list for all initial Entities.
    public static ImageInfo[] VEG_IMAGES = { 
        new ImageInfo("flower.gif", 34, 34),
        new ImageInfo("tree.gif", 83, 87),
        new ImageInfo("grass.gif", 51, 53),
        new ImageInfo("bush.gif", 103, 89) };

    // The base constructor:
    // Creates a new entity attached to the passed-in game,
    // prepares all its variables, and increments the <nextId>.
    public Entity(DukeGame game)
    {
        this.game = game;
        x = gen.Next(MARGIN, game.GetMaxWidth() - MARGIN);
        y = gen.Next(MARGIN, game.GetMaxHeight() - MARGIN);
        speed = gen.Next(10) + 5;
        dir = gen.Next(360);
        int imgNum = gen.Next(VEG_IMAGES.Length);
        image = VEG_IMAGES[imgNum];
        audio = "bush.wav";
        alive = true;

        id = nextId;

        nextId++; // increment to be ready for next object that is created

    }

    // returns true if the entity is outside the borders
    public bool IsOutOfBounds()
    {
        return x < MARGIN || x > game.GetMaxWidth() - MARGIN || y < MARGIN || y > game.GetMaxHeight() - MARGIN;
    }

    // moves the entity to a new position, based on its current position, heading, and speed
    public void UpdatePosition()
    {
        if (IsOutOfBounds())
        {
            // make it bounce!
            dir = (dir + 180) % 360;
        }
        x = x + speed * Math.Cos(dir * Math.PI / 180);
        y = y - speed * Math.Sin(dir * Math.PI / 180);
    }

    // Process  a click on this entity
    public virtual void Clicked() { }

    // Returns an SVG representation of this Entity
    public virtual string Draw()
    {
        const string ENTITY_SVG = @"
          <a xlink:href='DukeHunt.ashx?action=click&amp;id={ID}'>
            <image x='{X}' y='{Y}' xlink:href='img/{FILENAME}' width='{WIDTH}' height='{HEIGHT}' />
          </a>";
        return ENTITY_SVG.Replace("{ID}", id.ToString())
            .Replace("{X}", GetX().ToString())
            .Replace("{Y}", GetY().ToString())
            .Replace("{FILENAME}", image.GetFilename())
            .Replace("{WIDTH}", image.GetWidth().ToString())
            .Replace("{HEIGHT}", image.GetHeight().ToString());
    }

    // Kills the current Entity
    public virtual void Kill()
    {
        alive = false;
        speed = 0;
    }

    // Resets the ID (used when a new game is started...)
    public static void ResetID() { nextId = 0; }

    // ---------------------- Accessor methods -----------------------
    public ImageInfo GetImage() { return image; }
    public int GetX() { return (int)x; }
    public int GetY() { return (int)y; }
    public int GetId() { return id; }
    public string GetAudio() { return audio; }
    public bool IsAlive() { return alive; }
    public static int LoopID() { return nextId; }

    // ---------------------Mutator methods --------------------------
    public void SetSpeed(int newSpeed) { speed = newSpeed; }
    public void SetImage(ImageInfo newImage) { image = newImage; }
}



class Duke : Entity
{
    // If false, Duke is hidden; if true, Duke is revealed.
    private bool revealed;

    // Constructor for Duke
    // ...sets standard Duke parameters.
    public Duke(DukeGame game)
        : base(game)
    {
        revealed = false;
        audio = "giggles.wav";
    }

    // Processes the "click" event...
    // If the duke has not previously been revealed, it is revealed
    // and DukeGame's "FoundDuke" method is updated.
    public override void Clicked()
    {
        if (this.revealed == false)
        {
            this.revealed = true;
            this.SetImage(new ImageInfo("duke.gif", 50, 56));

            game.FoundDuke();
        }
    }

    // If Cheat Mode is activated, this adds a blue line underneath all dukes on the screen
    // ...living or dead, revealed or hidden.
    public override string Draw()
    {
        string ENTITY_SVG = base.Draw();
        if (game.GetCheat() == true)
        {
            ENTITY_SVG += "<image x='" + GetX().ToString() + "' y='" + (GetY() + GetImage().GetHeight()).ToString() + "' xlink:href='img/dukecue.gif' width='" + GetImage().GetWidth().ToString() + "' height='56' />";
        }
        return ENTITY_SVG;
    }

    // This kills the Duke, checks if it has been revealed or not, and updates the game as necessary.
    public override void Kill()
    {
        base.Kill();
        this.SetImage(new ImageInfo("ghost.gif", 74, 104));
        if (this.revealed == false)
        {
            this.revealed = true;
            game.FoundDuke();
        }
    }
}



class Vegetation : Entity
{
    // Creates a new vegetation and sets its speed to 0.
    public Vegetation(DukeGame game)
        : base(game)
    {
        SetSpeed(0);
    }

    // Performs the basic "Kill" command and then changes the image to a flame.
    public override void Kill()
    {
        base.Kill();
        this.SetImage(new ImageInfo("fire.gif", 30, 60));
    }
}



class Decoy : Entity
{
    // Keeps track of the detonation status of this decoy.
    private bool detonated;


    // Creates a new decoy and sets its special parameters.
    public Decoy(DukeGame game)
        : base(game)
    {
        detonated = false;
        audio = "explosion.wav";
    }

    // If Cheat Mode is activated, this adds a red line underneath all decoys on the screen
    // ...detonated or hidden.
    public override string Draw()
    {
        string ENTITY_SVG = base.Draw();
        if (game.GetCheat() == true)
        {
            ENTITY_SVG += "<image x='" + GetX().ToString() + "' y='" + (GetY() + GetImage().GetHeight()).ToString() + "' xlink:href='img/decoycue.gif' width='" + GetImage().GetWidth().ToString() + "' height='56' />";
        }
        return ENTITY_SVG;
    }

    // Performs the basic "Kill" command and then executes MultiKill
    // to wreak as much damage as possible.
    public override void Kill()
    {
        base.Kill();
        this.detonated = true;
        this.SetImage(new ImageInfo("explosion.gif", 71, 100));
        this.MultiKill();
    }

    // Processes the "click" event...
    // If the decoy has not been previously detonated, it is now.
    public override void Clicked()
    {
        if (this.detonated == false)
        {
            this.Kill();
        }
    }

    // Checks a 150px radius around the exploding decoy and calls the kill command
    // on any living entity found therein.
    public void MultiKill()
    {
        for (int i = 0; i < game.EntCount(); i++)
        {
            // Indivudually check every entity in the game...
            Entity e = game.FindEntity(i);
            if (e != null && e.GetId() != this.GetId())
            {
                // ...to see if it is in a 150 pixel radius of the exploding decoy...
                // ...and alive.
                if (Math.Sqrt((double)Math.Pow((e.GetX() - this.GetX()), 2) + (double)Math.Pow((e.GetY() - this.GetY()), 2)) <= 150 && e.IsAlive() == true)
                {
                    // Terminate if it is.
                    e.Kill();
                }
            }
        }
    }
}


class ImageInfo
{
    private string filename;
    private int width, height;

    public ImageInfo(string filename, int width, int height)
    {
        this.filename = filename;
        this.width = width;
        this.height = height;
    }

    public string GetFilename() { return filename; }
    public int GetWidth() { return width; }
    public int GetHeight() { return height; }
}

class DukeGame
{

    private Entity[] entityList; // the master Entity list

    private int maxWidth, maxHeight; // width and height of browser window

    private int turns, hidden_dukes, starting_dukes;

    private bool cheat; // Variable toggled on action='cheat'

    protected string sound_file;


    public DukeGame(int numDukes, int maxWidth, int maxHeight)
    {
        Entity.ResetID();
        starting_dukes = numDukes;
        entityList = new Entity[(numDukes * 5) + (numDukes * 2)];

        this.maxWidth = maxWidth;
        this.maxHeight = maxHeight;

        int curSlot = 0;
        hidden_dukes = numDukes;
        turns = 0;

        // Adds vegetation to <entityList>
        for (int i = 0; i < numDukes * 5; i++)
        {
            entityList[curSlot] = new Vegetation(this);
            curSlot++;
        }
        // Adds decoys to <entityList>
        for (int i = curSlot; i < (numDukes * 5) + (numDukes); i++)
        {
            entityList[curSlot] = new Decoy(this);
            curSlot++;
        }
        // Adds dukes to <entityList>
        for (int i = curSlot; i < entityList.Length; i++)
        {
            entityList[curSlot] = new Duke(this);
            curSlot++;
        }


    }


    // Displays all entities in the world
    public string ShowEntities()
    {
        string entitySvg = "";

        for (int i = 0; i < entityList.Length; i++)
        {
            Entity ent = entityList[i];
            entitySvg += ent.Draw();
        }
        return entitySvg;
    }

    // Updates all Entity coordinates
    public void UpdateEntityPositions()
    {
        turns++;
        for (int i = 0; i < entityList.Length; i++)
        {
            entityList[i].UpdatePosition();
        }
    }

    // Processes a Click event for entity with given <id>
    public void Clicked(int id)
    {
        turns = turns + 4;
        Entity ent = FindEntity(id);
        if (ent != null)
        {
            ent.Clicked();
            sound_file = ent.GetAudio();
        }
    }

    // Returns entity with <id> from entityList, or NULL if no entity has the specified <id>
    public Entity FindEntity(int id)
    {
        foreach (Entity ent in entityList)
        {
            if (ent.GetId() == id)
            {
                return ent;
            }
        }
        return null;
    }

    // Decrements hidden_dukes (called when a hidden duke is clicked)
    public void FoundDuke() { hidden_dukes = (hidden_dukes - 1); }

    // toggles the condition of <cheat> (called by DukeHunt when action=cheat)
    public void CheatMode()
    {
        cheat = !cheat;
    }
    // Resets the former audio tag to keep "UpdateEntityPositions" from replaying the "Clicked" audio tag.
    public void ClearAudio() { sound_file = "bush.wav"; }

    // ------------------------ Accessor methods --------------------

    public int GetMaxWidth() { return maxWidth; }
    public int GetMaxHeight() { return maxHeight; }
    public int GetTurns() { return turns; }
    public int Undiscovered() { return hidden_dukes; }
    public bool GetCheat() { return cheat; }
    public string SendAudio() { return sound_file; }
    public int EntCount() { return entityList.Length; }
    public int StartCount() { return starting_dukes; }
}

public class DukeHunt : IHttpHandler, System.Web.SessionState.IRequiresSessionState
{
    private static DukeGame game;

    public void ProcessRequest(HttpContext context)
    {

        /*
          try {
            game = (DukeGame)context.Session["DukeHunt"];
          } catch {        
            // Application recompiled; reset game
            game = null;
          }     
        */

        string action = context.Request["action"];

        if (action != "Start Game" && game == null)
        {
            action = null;
        }

        switch (action)
        {
            case "Start Game":
                {
                    int numDukes = Convert.ToInt32(context.Request["numdukes"]);
                    int width = Convert.ToInt32(context.Request["width"]) - 50;
                    int height = Convert.ToInt32(context.Request["height"]) - 125;
                    game = new DukeGame(numDukes, width, height);
                    PrintWorld(context, game);
                    break;

                }
            case "cheat":
                {
                    game.ClearAudio();
                    game.CheatMode();
                    PrintWorld(context, game);
                    break;
                }
            case "view":
                {
                    game.ClearAudio();
                    game.UpdateEntityPositions();
                    PrintWorld(context, game);
                    break;
                }
            case "click":
                {
                    game.ClearAudio();
                    int id = Convert.ToInt32(context.Request["id"]);
                    game.Clicked(id);
                    game.UpdateEntityPositions();
                    PrintWorld(context, game);
                    break;

                }
            default:
                PrintTitleScreen(context);
                break;

        }

        // context.Session["DukeHunt] = game;

    }

    // Display a title screen
    void PrintTitleScreen(HttpContext context)
    {
        using (StreamReader rd = new StreamReader(context.Server.MapPath("TitleScreen.html")))
        {
            context.Response.Write(rd.ReadToEnd());
        }
    }

    // Displays the world
    void PrintWorld(HttpContext context, DukeGame game)
    {
        context.Response.ContentType = "text/xml";
        string svgData = game.ShowEntities();
        if (game.Undiscovered() == 0)
        {
            svgData += "<text x='50' y='50' font-family='Verdana' font-size='24pt' stroke='blue'>Game Over</text>";
            svgData += "<text x='65' y='75' font-family='Verdana' font-size='18pt' stroke='red'>";
            if(game.GetTurns() <= game.StartCount() * 5)
            {
                svgData += "You played magnificently!</text>";
            }
            else if (game.GetTurns() <= game.StartCount() * 10)
            {
                svgData += "You played moderately well...</text>";
            }
            else if (game.GetTurns() <= game.StartCount() * 20)
            {
                svgData += "You played poorly!</text>";
            }
            else
            {
                svgData +="Have you ever played a video game before...?</text>";
            }
        }
        using (StreamReader rd = new StreamReader(context.Server.MapPath("GameScreen.xml")))
        {
            string html = rd.ReadToEnd();
            context.Response.Write(html.Replace("{WIDTH}", game.GetMaxWidth().ToString())
              .Replace("{HEIGHT}", game.GetMaxHeight().ToString())
              .Replace("{SVGDATA}", svgData)
              .Replace("{TURNS}", game.GetTurns().ToString())
              .Replace("{HIDDEN}", game.Undiscovered().ToString())
              .Replace("{AUDIO}", game.SendAudio()));
        }

    }

    public bool IsReusable
    {
        get { return false; }
    }

}