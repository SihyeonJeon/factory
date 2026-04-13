/**
 * Supabase Database Types for Moment MVP
 * Generated from schema: 00001-00006 migrations
 *
 * In production, regenerate via: npx supabase gen types typescript --local
 */

export type EventMoodEnum =
  | "birthday"
  | "running"
  | "wine"
  | "book"
  | "houseparty"
  | "salon";

export type RsvpStatusEnum = "attending" | "declined" | "maybe";
export type FeeIntentionEnum = "will_pay" | "undecided";
export type ReminderTypeEnum = "d1" | "manual";

export interface ColorTheme {
  primary: string;
  bg: string;
  accent: string;
}

export interface ParticipantStatus {
  user_id: string;
  display_name: string;
  paid: boolean;
}

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          kakao_id: string | null;
          display_name: string;
          avatar_url: string | null;
          created_at: string;
        };
        Insert: {
          id: string;
          kakao_id?: string | null;
          display_name?: string;
          avatar_url?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          kakao_id?: string | null;
          display_name?: string;
          avatar_url?: string | null;
          created_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "profiles_id_fkey";
            columns: ["id"];
            isOneToOne: true;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
        ];
      };
      fcm_tokens: {
        Row: {
          user_id: string;
          token: string;
          updated_at: string;
        };
        Insert: {
          user_id: string;
          token: string;
          updated_at?: string;
        };
        Update: {
          user_id?: string;
          token?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "fcm_tokens_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: true;
            referencedRelation: "users";
            referencedColumns: ["id"];
          },
        ];
      };
      events: {
        Row: {
          id: string;
          host_id: string;
          title: string;
          datetime: string;
          location: string;
          mood: EventMoodEnum;
          cover_image_url: string | null;
          color_theme: ColorTheme;
          description: string;
          has_fee: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          host_id: string;
          title: string;
          datetime: string;
          location?: string;
          mood?: EventMoodEnum;
          cover_image_url?: string | null;
          color_theme?: ColorTheme;
          description?: string;
          has_fee?: boolean;
          created_at?: string;
        };
        Update: {
          id?: string;
          host_id?: string;
          title?: string;
          datetime?: string;
          location?: string;
          mood?: EventMoodEnum;
          cover_image_url?: string | null;
          color_theme?: ColorTheme;
          description?: string;
          has_fee?: boolean;
          created_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "events_host_id_fkey";
            columns: ["host_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      guest_states: {
        Row: {
          id: string;
          event_id: string;
          user_id: string;
          status: RsvpStatusEnum;
          companion_count: number;
          fee_intention: FeeIntentionEnum | null;
          responded_at: string;
        };
        Insert: {
          id?: string;
          event_id: string;
          user_id: string;
          status?: RsvpStatusEnum;
          companion_count?: number;
          fee_intention?: FeeIntentionEnum | null;
          responded_at?: string;
        };
        Update: {
          id?: string;
          event_id?: string;
          user_id?: string;
          status?: RsvpStatusEnum;
          companion_count?: number;
          fee_intention?: FeeIntentionEnum | null;
          responded_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "guest_states_event_id_fkey";
            columns: ["event_id"];
            isOneToOne: false;
            referencedRelation: "events";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "guest_states_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      media_timeline: {
        Row: {
          id: string;
          event_id: string;
          uploader_id: string;
          storage_path: string;
          thumbnail_path: string | null;
          width: number | null;
          height: number | null;
          uploaded_at: string;
        };
        Insert: {
          id?: string;
          event_id: string;
          uploader_id: string;
          storage_path: string;
          thumbnail_path?: string | null;
          width?: number | null;
          height?: number | null;
          uploaded_at?: string;
        };
        Update: {
          id?: string;
          event_id?: string;
          uploader_id?: string;
          storage_path?: string;
          thumbnail_path?: string | null;
          width?: number | null;
          height?: number | null;
          uploaded_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "media_timeline_event_id_fkey";
            columns: ["event_id"];
            isOneToOne: false;
            referencedRelation: "events";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "media_timeline_uploader_id_fkey";
            columns: ["uploader_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
      settlements: {
        Row: {
          id: string;
          event_id: string;
          total_amount: number;
          per_person: number;
          participant_statuses: ParticipantStatus[];
          created_at: string;
        };
        Insert: {
          id?: string;
          event_id: string;
          total_amount: number;
          per_person: number;
          participant_statuses?: ParticipantStatus[];
          created_at?: string;
        };
        Update: {
          id?: string;
          event_id?: string;
          total_amount?: number;
          per_person?: number;
          participant_statuses?: ParticipantStatus[];
          created_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "settlements_event_id_fkey";
            columns: ["event_id"];
            isOneToOne: true;
            referencedRelation: "events";
            referencedColumns: ["id"];
          },
        ];
      };
      reminders: {
        Row: {
          id: string;
          event_id: string;
          type: ReminderTypeEnum;
          sent_at: string;
          fcm_batch_id: string | null;
        };
        Insert: {
          id?: string;
          event_id: string;
          type?: ReminderTypeEnum;
          sent_at?: string;
          fcm_batch_id?: string | null;
        };
        Update: {
          id?: string;
          event_id?: string;
          type?: ReminderTypeEnum;
          sent_at?: string;
          fcm_batch_id?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: "reminders_event_id_fkey";
            columns: ["event_id"];
            isOneToOne: false;
            referencedRelation: "events";
            referencedColumns: ["id"];
          },
        ];
      };
    };
    Views: Record<string, never>;
    Functions: {
      mark_participant_paid: {
        Args: { p_event_id: string; p_user_id: string };
        Returns: ParticipantStatus[];
      };
    };
    Enums: {
      event_mood: EventMoodEnum;
      rsvp_status: RsvpStatusEnum;
      fee_intention: FeeIntentionEnum;
      reminder_type: ReminderTypeEnum;
    };
    CompositeTypes: Record<string, never>;
  };
}
